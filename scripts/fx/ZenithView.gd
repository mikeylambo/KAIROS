class_name ZenithView
extends Node2D
## Procedural Zenith (LOCKED look): black sleeveless high-neck top, sash, wrapped
## forearms/shins, loose trousers, bare feet, porcelain skin with light cracks,
## swept hair dissolving into motes, two shoulder ribbons, cyan/magenta rim.
## The life clock reads three ways: ribbon length (5-min bands), crack width,
## chest light in the final 2:00.

const CYAN := Color("#3FF6FF")
const MAGENTA := Color("#FF3FD8")
const SKIN := Color(0.93, 0.92, 0.95)
const CLOTH := Color(0.035, 0.035, 0.045)
const SEGS: int = 14

var cam: GameCamera
var ribbons: Array[Line2D] = []
var pts: Array = [[], []]
var t: float = 0.0
var dissolve: float = 0.0
var sprite: AnimatedSprite2D = null

func _ready() -> void:
	var sh: Shader = load("res://scripts/fx/shaders/ribbon.gdshader")
	var tex := GradientTexture1D.new()
	tex.gradient = Gradient.new()
	for i: int in 2:
		var l := Line2D.new()
		l.top_level = true
		l.texture = tex
		l.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.width = 14.0
		var wc := Curve.new()
		wc.add_point(Vector2(0, 0.55))
		wc.add_point(Vector2(0.3, 1.0))
		wc.add_point(Vector2(1, 0.7))
		l.width_curve = wc
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("end_color", CYAN if i == 0 else MAGENTA)
		l.material = m
		l.z_index = -1
		add_child(l)
		ribbons.append(l)
	var path: String = Tuning.assets.resolve(&"sprite_zenith")
	if path != "":
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = load(path)
		sprite.scale = Vector2(0.4, 0.4)
		add_child(sprite)

func life() -> float:
	return clampf(Run.clock.remaining / maxf(1.0, Run.clock.start), 0.0, 1.0)

func _process(delta: float) -> void:
	t += delta
	if cam == null or cam.sim == null or cam.sim.zenith == null:
		return
	var z: Zenith = cam.sim.zenith
	global_position = cam.vp(z.pos)
	_update_ribbons(z, delta)
	if sprite:
		sprite.flip_h = z.facing < 0
		sprite.play(_anim_name(z))
	queue_redraw()

func _anim_name(z: Zenith) -> String:
	match z.state:
		Zenith.S.ATTACK:
			return z.combat.move_id
		Zenith.S.GUARD:
			return "guard"
		Zenith.S.BEAM_CHARGE, Zenith.S.BEAM_FIRE:
			return "beam"
		Zenith.S.STAGGER:
			return "hit"
	if z.burst_t > 0:
		return "burst"
	if z.flying:
		return "fly"
	return "run" if absf(z.vel.x) > 60.0 else "idle"

func tilt(z: Zenith) -> float:
	if not z.flying:
		return clampf(z.vel.x / (18.0 * 32.0), -1.0, 1.0) * 0.08
	return clampf(z.vel.x / (28.0 * 32.0), -1.0, 1.0) * deg_to_rad(Tuning.t.fly_bank_deg)

func _update_ribbons(z: Zenith, delta: float) -> void:
	var length: float = (34.0 + 150.0 * life()) * (1.0 - dissolve)
	var seg: float = length / float(SEGS - 1)
	var rot: float = tilt(z)
	for i: int in 2:
		var anchor: Vector2 = global_position + Vector2(-z.facing * (4.0 + i * 5.0), -16.0).rotated(rot)
		var arr: Array = pts[i]
		if arr.size() != SEGS:
			arr.clear()
			for k: int in SEGS:
				arr.append(anchor + Vector2(-z.facing * seg * k, 0))
		arr[0] = anchor
		var back: Vector2 = (Vector2(-z.facing, -0.25 + 0.12 * i) - z.vel / 1400.0).normalized()
		for k: int in range(1, SEGS):
			var wave: Vector2 = Vector2(0, sin(t * 3.2 + k * 0.55 + i * 1.7) * (1.5 + k * 0.35))
			var want: Vector2 = (arr[k - 1] as Vector2) + back * seg + wave
			arr[k] = (arr[k] as Vector2).lerp(want, clampf(delta * 14.0, 0.0, 1.0))
			var d: Vector2 = (arr[k] as Vector2) - (arr[k - 1] as Vector2)
			if d.length() > seg:
				arr[k] = (arr[k - 1] as Vector2) + d.normalized() * seg
		ribbons[i].points = PackedVector2Array(arr)
		(ribbons[i].material as ShaderMaterial).set_shader_parameter("time_s", t)
		ribbons[i].modulate.a = 1.0 - dissolve

func _draw() -> void:
	if cam == null or cam.sim == null or sprite != null:
		_draw_ki()
		return
	var z: Zenith = cam.sim.zenith
	var f: float = float(z.facing)
	draw_set_transform(Vector2.ZERO, tilt(z), Vector2(f, 1.0) * 1.12)
	var a: float = 1.0 - dissolve
	var bob: float = sin(t * 2.4) * 2.0 if z.flying or not z.on_floor else 0.0
	var o: Vector2 = Vector2(0, bob)
	var run_k: float = sin(t * 16.0) if z.on_floor and absf(z.vel.x) > 60.0 else 0.0
	var pose: Dictionary = _pose(z)
	_limb(o + Vector2(-3, 6), o + Vector2(-5 - run_k * 8.0, 18), o + Vector2(-4 - run_k * 12.0, 29), 7.0, a)
	_limb(o + Vector2(3, 6), o + Vector2(5 + run_k * 8.0, 18), o + Vector2(6 + run_k * 12.0, 29), 7.0, a)
	_arm(o + Vector2(-4, -12), pose["back"], a, false)
	var torso := PackedVector2Array([o + Vector2(-7, -16), o + Vector2(7, -16), o + Vector2(6, 4), o + Vector2(-6, 4)])
	draw_colored_polygon(torso, Color(CLOTH, a))
	draw_rect(Rect2(o + Vector2(-3, -21), Vector2(6, 6)), Color(CLOTH, a))
	draw_rect(Rect2(o + Vector2(-7, 1), Vector2(14, 4)), Color(0.0, 0.0, 0.0, a))
	draw_line(o + Vector2(-6, 4), o + Vector2(-10, 12), Color(0, 0, 0, a), 2.0)
	draw_circle(o + Vector2(1, -26), 6.0, Color(SKIN, a))
	var hair := PackedVector2Array([o + Vector2(-5, -31), o + Vector2(5, -32), o + Vector2(7, -28), o + Vector2(-3, -27), o + Vector2(-12, -25), o + Vector2(-9, -29)])
	draw_colored_polygon(hair, Color(0.08, 0.08, 0.1, a))
	for k: int in 6:
		var mt: float = fposmod(t * 0.8 + k * 0.17, 1.0)
		draw_circle(o + Vector2(-10 - mt * 22.0, -27 - mt * 6.0 + sin(k * 3.0 + t * 2.0) * 3.0), 1.6 * (1.0 - mt), Color(1.4, 1.4, 1.6, (1.0 - mt) * a))
	_arm(o + Vector2(4, -12), pose["front"], a, true)
	_cracks(o, a)
	_rim(o, a)
	if Run.clock.remaining < Run.clock.start * (120.0 / 1800.0) and Run.clock.phase != RunClock.Phase.FADED:
		var k2: float = 1.0 - Run.clock.remaining / (Run.clock.start * (120.0 / 1800.0))
		var pulse: float = 0.6 + 0.4 * sin(t * (4.0 + k2 * 8.0))
		draw_circle(o + Vector2(0, -9), 3.0 + 5.0 * k2, Color(2.0, 2.4, 2.6, pulse * a))
		draw_circle(o + Vector2(0, -9), 9.0 + 10.0 * k2, Color(0.25, 0.96, 1.0, 0.25 * pulse * a))
	if Run.clock.phase == RunClock.Phase.FADE_FIGHT:
		draw_circle(o + Vector2(0, -9), 6.0, Color(2.4, 2.4, 2.6, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_ki()
	if z.combat.beam_t > 0 or z.state == Zenith.S.BEAM_CHARGE:
		_draw_beam(z)

func _pose(z: Zenith) -> Dictionary:
	var c: ZenithCombat = z.combat
	var relaxed := {"front": [Vector2(10, -2), Vector2(12, 8)], "back": [Vector2(-9, -2), Vector2(-10, 8)]}
	match z.state:
		Zenith.S.ATTACK:
			var prog: float = clampf(float(c.frame) / float(maxi(1, c.startup + c.active)), 0.0, 1.0)
			if c.move_id == "heavy":
				var d: Vector2 = Vector2(absf(c.launch_dir.x) if absf(c.launch_dir.x) > 0.1 else 0.3, c.launch_dir.y)
				return {"front": [d * 10.0, d * (14.0 + 10.0 * prog)], "back": [d * 8.0 + Vector2(-2, 3), d * 18.0 * prog]}
			var reach: float = 8.0 + 16.0 * prog
			var lo: float = -4.0 if c.move_id == "light1" else 0.0
			return {"front": [Vector2(10, -6 + lo), Vector2(reach + 6, -8 + lo)], "back": [Vector2(-6, 0), Vector2(-2, -6)]}
		Zenith.S.GUARD:
			return {"front": [Vector2(8, -8), Vector2(2, -18)], "back": [Vector2(6, -4), Vector2(-2, -14)]}
		Zenith.S.BEAM_CHARGE, Zenith.S.BEAM_FIRE, Zenith.S.VOLLEY:
			var bd: Vector2 = Vector2(absf(c.beam_dir.x), c.beam_dir.y)
			return {"front": [bd * 10.0, bd * 22.0], "back": [bd * 9.0 + Vector2(0, 2), bd * 20.0 + Vector2(0, 2)]}
		Zenith.S.STAGGER:
			return {"front": [Vector2(-4, -12), Vector2(-10, -20)], "back": [Vector2(-8, -6), Vector2(-16, -10)]}
	return relaxed

func _arm(shoulder: Vector2, p: Array, a: float, front: bool) -> void:
	var elbow: Vector2 = shoulder + (p[0] as Vector2) * 0.6
	var hand: Vector2 = shoulder + (p[1] as Vector2)
	draw_line(shoulder, elbow, Color(SKIN.darkened(0.0 if front else 0.15), a), 4.5)
	draw_line(elbow, hand, Color(0.06, 0.06, 0.07, a), 5.0)
	draw_circle(hand, 2.6, Color(SKIN, a))

func _limb(hip: Vector2, knee: Vector2, foot: Vector2, w: float, a: float) -> void:
	draw_line(hip, knee, Color(CLOTH, a), w + 1.5)
	draw_line(knee, foot - Vector2(0, 4), Color(CLOTH.lightened(0.04), a), w)
	draw_line(foot - Vector2(0, 5), foot - Vector2(0, 1), Color(0.07, 0.07, 0.08, a), 4.5)
	draw_line(foot, foot + Vector2(4, 0), Color(SKIN, a), 2.5)

func _cracks(o: Vector2, a: float) -> void:
	var k: float = 1.0 - life()
	var w: float = 0.6 + k * 2.6
	var col := Color(1.6 + k, 2.2 + k, 2.4 + k, (0.35 + 0.65 * k) * a)
	draw_line(o + Vector2(2, -31), o + Vector2(4, -27) + Vector2(k * 2, k * 3), col, w)
	if k > 0.2:
		draw_line(o + Vector2(-2, -24), o + Vector2(3, -21), col, w)
	if k > 0.4:
		draw_line(o + Vector2(-3, -20), o + Vector2(-1, -14), col, w * 0.8)
		draw_line(o + Vector2(14, -10), o + Vector2(17, -6), col, w * 0.8)
	if k > 0.6:
		draw_line(o + Vector2(5, -29), o + Vector2(-2, -30), col, w)
		draw_line(o + Vector2(-12, -8), o + Vector2(-9, -2), col, w * 0.8)
	if k > 0.8:
		draw_line(o + Vector2(0, -16), o + Vector2(2, -4), col, w)

func _rim(o: Vector2, a: float) -> void:
	draw_line(o + Vector2(8, -16), o + Vector2(7, 4), Color(CYAN * 1.6, 0.8 * a), 1.5)
	draw_arc(o + Vector2(1, -26), 7.0, -1.2, 0.9, 10, Color(CYAN * 1.6, 0.8 * a), 1.5)
	draw_line(o + Vector2(-8, -16), o + Vector2(-7, 4), Color(MAGENTA * 1.5, 0.7 * a), 1.5)
	draw_arc(o + Vector2(1, -26), 7.0, 2.2, 4.0, 10, Color(MAGENTA * 1.5, 0.7 * a), 1.5)

func _draw_ki() -> void:
	if cam == null or cam.sim == null:
		return
	var z: Zenith = cam.sim.zenith
	var mx: float = z.ki_max()
	var c: Vector2 = Vector2(0, 30)
	var r: float = 26.0
	var a0: float = PI * 0.2
	var a1: float = PI * 0.8
	draw_arc(c, r, a0, a1, 24, Color(1, 1, 1, 0.12), 2.0)
	var fk: float = z.ki / mx
	if fk > 0.0:
		draw_arc(c, r, a1 - (a1 - a0) * fk, a1, 24, Color(0.4, 1.9, 2.0, 0.9), 2.5)
	for th: float in [Tuning.t.ki_volley, Tuning.t.ki_field, Tuning.t.ki_beam]:
		var ang: float = a1 - (a1 - a0) * (th / mx)
		var lit: bool = z.ki >= th
		draw_line(c + Vector2(cos(ang), sin(ang)) * (r - 4), c + Vector2(cos(ang), sin(ang)) * (r + 4), Color(1, 1, 1, 0.9 if lit else 0.3), 1.5)

func _draw_beam(z: Zenith) -> void:
	var c: ZenithCombat = z.combat
	var dir: Vector2 = c.beam_dir
	if z.state == Zenith.S.BEAM_CHARGE:
		var r: float = 6.0 + 16.0 * c.beam_charge
		draw_circle(dir * 22.0, r * 1.8, Color(0.25, 0.96, 1.0, 0.25))
		draw_circle(dir * 22.0, r, Color(2.2, 2.4, 2.6))
		return
	var w: float = ZenithKi.beam_width(c)
	var length: float = 40.0 * 32.0
	var flick: float = 1.0 + 0.08 * sin(t * 50.0)
	draw_line(dir * 20.0, dir * length, Color(0.25, 0.96, 1.0, 0.35), w * 1.9 * flick)
	draw_line(dir * 20.0, dir * length, Color(1.0, 0.25, 0.85, 0.35), w * 1.3 * flick)
	draw_line(dir * 20.0, dir * length, Color(2.6, 2.6, 2.8), w * 0.7)
	draw_circle(dir * 22.0, w * 0.9, Color(2.6, 2.6, 2.8))
	for sp: Vector2 in cam.sim.split_points:
		var local: Vector2 = cam.vp(sp) - global_position
		for s: float in [-0.45, 0.45]:
			var d2: Vector2 = dir.rotated(s)
			draw_line(local, local + d2 * 16.0 * 32.0, Color(2.2, 2.0, 2.6, 0.8), w * 0.45)
