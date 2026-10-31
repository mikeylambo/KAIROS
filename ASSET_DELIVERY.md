# ASSET DELIVERY

Every asset loads by key through `data/asset_manifest.tres`. Missing file → procedural stand-in (already in game). Drop files at the listed paths; no code change.

**Pipeline:** Meshy (image-to-3D / text-to-3D) → Mixamo or Blender rig → `tools/blender/render_sprites.py` → PNGs into `assets/sprites/<key>/` → build a `SpriteFrames` resource at `assets/sprites/<key>/<key>.tres` with one animation per action (names below).

| Key | Source | Prompt / reference | Export spec | Status |
|---|---|---|---|---|
| `sprite_zenith` | Meshy image-to-3D from the locked concept | Black sleeveless high-neck top, black sash, black wrapped forearms and shins, loose black trousers, bare feet, porcelain skin with hairline light cracks, smooth swept-back hair dissolving into motes, two light ribbons from shoulder blades (cyan/magenta frayed ends). No spikes, no vest/sash DBZ echoes | 256×256, ortho side, 3 px outline, 24 fps attacks / 12 fps loops. Anims: `idle`, `run`, `fly`, `burst`, `light0`, `light1`, `light2`, `heavy`, `guard`, `beam`, `hit`. Ribbons stay procedural (Line2D) | Procedural stand-in final-quality; sprite pending |
| `sprite_drone` | Meshy text-to-3D | "hovering civic crisis drone, rotor arms, single orange sensor eye, worn grey municipal paint" | 128×128; idle/move/attack/hit/die | stand-in |
| `sprite_brute` | Meshy text-to-3D | "hunched heavy riot automaton, slab shoulders, orange visor slit" | 192×192; + windup | stand-in |
| `sprite_slammer` | Meshy text-to-3D | "iron-plated crusher golem, rivets, heavy fists, three armor plates on back" | 192×192; + slam | stand-in |
| `sprite_gunner` | Meshy text-to-3D | "lean artillery sentinel with long barrel, iron grey, orange muzzle" | 128×128; + shot | stand-in |
| `sprite_flyer` | Meshy text-to-3D (flag: non-humanoid rig in Blender) | "pale sky creature, wide light wings, small dark body" | 128×128; flap/dive/hit/fall | stand-in |
| `sprite_lancer` | Meshy text-to-3D (non-humanoid) | "spear-shaped sky knight, swept fins, long lance" | 192×192; charge | stand-in |
| `sprite_bloom` | Meshy + Blender (non-humanoid, 3 phases) | "magenta bioluminescent flower core, layered petals, vines" | 512×512; per phase | stand-in |
| `bg_<dim>_<0-4>` (threshold, leadfall, skyreach, corridor) | AI 2D painterly | Threshold: dusk city skyline. Leadfall: iron monoliths, iron rain. Skyreach: open sky, cloud banks, far spires. Corridor: starfield streaks | 3840×2160 PNG per layer, tileable horizontally, desaturate 25%, palette-matched to `data/dimensions/*.tres` | stand-in |
| Tiles | Hand TileSet | — | 32 px | flat-colour tiles with rim lines (final until art) |
| VFX, UI | Procedural | — | — | **final** |
