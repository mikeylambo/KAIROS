"""Render a rigged model's actions to KAIROS sprite sheets (GDD §13 export spec).

Usage (Blender 4.x):
  blender model.blend --background --python tools/blender/render_sprites.py -- \
      --key zenith --size 256 --out assets/sprites/zenith --fps-attack 24 --fps-loop 12

- Orthographic side camera framing the armature's bounds, transparent film.
- 3 px outline via Freestyle (line thickness scaled to frame size).
- Every action in the file is rendered; frames named <key>_<action>_<frame>.png.
- Actions whose name starts with light/heavy/burst/beam/hit render at --fps-attack,
  the rest at --fps-loop.
"""
import argparse
import os
import sys

import bpy
from mathutils import Vector

ATTACK_PREFIXES = ("light", "heavy", "burst", "beam", "hit", "guard", "volley", "field")


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--key", required=True)
    p.add_argument("--size", type=int, default=256)
    p.add_argument("--out", required=True)
    p.add_argument("--fps-attack", type=int, default=24)
    p.add_argument("--fps-loop", type=int, default=12)
    p.add_argument("--outline", type=float, default=3.0)
    return p.parse_args(argv)


def find_armature():
    for ob in bpy.context.scene.objects:
        if ob.type == "ARMATURE":
            return ob
    raise SystemExit("no armature in scene")


def setup_scene(a, arm):
    sc = bpy.context.scene
    sc.render.resolution_x = a.size
    sc.render.resolution_y = a.size
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    sc.render.line_thickness = a.outline
    vl = sc.view_layers[0]
    vl.use_freestyle = True
    cam_data = bpy.data.cameras.new("kairos_cam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("kairos_cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    meshes = [o for o in sc.objects if o.type == "MESH"]
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    extent = max(hi.x - lo.x, hi.z - lo.z) * 1.35
    cam_data.ortho_scale = extent
    cam.location = (center.x, lo.y - 10.0, center.z)
    cam.rotation_euler = (1.5708, 0.0, 0.0)  # side view looking +Y
    return sc


def render_actions(a, sc, arm):
    os.makedirs(a.out, exist_ok=True)
    if arm.animation_data is None:
        arm.animation_data_create()
    for action in bpy.data.actions:
        name = action.name.lower().replace(" ", "_")
        arm.animation_data.action = action
        start, end = (int(v) for v in action.frame_range)
        fps = a.fps_attack if name.startswith(ATTACK_PREFIXES) else a.fps_loop
        step = max(1, round(sc.render.fps / fps))
        idx = 0
        for f in range(start, end + 1, step):
            sc.frame_set(f)
            sc.render.filepath = os.path.join(a.out, f"{a.key}_{name}_{idx:02d}.png")
            bpy.ops.render.render(write_still=True)
            idx += 1
        print(f"rendered {a.key}:{name} → {idx} frames @ {fps} fps")


if __name__ == "__main__":
    a = args()
    arm = find_armature()
    sc = setup_scene(a, arm)
    render_actions(a, sc, arm)
