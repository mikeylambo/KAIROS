class_name EnemyView
extends Node2D
## Procedural enemy silhouettes per behavior (dimension palette + one warning hue),
## telegraphs with shape+color, launch glow + chase ring, bolts, echoes.

const U: float = 32.0
const WARN := Color("#FF8A1F")
var cam: GameCamera
var t: float = 0.0

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	if cam == null or cam.sim == null:
		return
	var s: Sim = cam.sim
	for e: EnemyBase in s.enemies:
		if e.alive:
			_enemy(e, s)
	for b: Dictionary in s.bolts:
		var p: Vector2 = cam.vp(b["pos"])
		var v: Vector2 = (b["vel"] as Vector2).normalized()
		var col: Color = Color(0.6, 1.8, 2.0) if b["friendly"] else Color(2.0, 0.9, 0.3)
		draw_line(p - v * 26.0, p, Color(col, 0.5), 6.0)
		draw_circle(p, 6.0, col)
	for m: Dictionary in s.echoes:
		var p2: Vector2 = cam.vp(m["pos"])
		var k: float = float(m["t"]) / 30.0
		draw_arc(p2, 20.0 + (1.0 - k) * 30.0, 0, TAU, 24, Color(1.0, 0.25, 0.85, k), 2.0)
		draw_rect(Rect2(p2 - Vector2(10, 28), Vector2(20, 56)), Color(0.25, 1.0, 1.0, 0.35 * k))

func _enemy(e: EnemyBase, s: Sim) -> void:
	var p: Vector2 = cam.vp(e.pos)
	var h: Vector2 = e.half
	var base: Color = e.def.color
	var dark: Color = base.darkened(0.55)
	if e.flash_t > 0:
		base = Color(2.2, 2.2, 2.2)
	var winding: bool = e.state == EnemyBase.S.WINDUP
	if winding and int(t * 20.0) % 2 == 0:
		base = base.lerp(WARN, 0.8)
	var f: float = float(e.facing)
	match e.def.behavior:
		&"drone", &"spore":
			var r: float = h.x
			draw_circle(p, r, dark)
			draw_circle(p, r * 0.72, base)
			draw_circle(p + Vector2(f * r * 0.3, 0), r * 0.25, WARN if e.def.behavior == &"drone" else Color(1.6, 0.4, 1.4))
			var rot: float = t * 18.0
			for k: int in 2:
				var a: float = rot + k * PI
				draw_line(p + Vector2(-r * 1.3, -r * 0.9), p + Vector2(-r * 1.3, -r * 0.9) + Vector2(cos(a), sin(a) * 0.3) * r, base, 2.0)
				draw_line(p + Vector2(r * 1.3, -r * 0.9), p + Vector2(r * 1.3, -r * 0.9) + Vector2(cos(a), sin(a) * 0.3) * r, base, 2.0)
		&"brute", &"slammer":
			var body := PackedVector2Array([p + Vector2(-h.x, h.y), p + Vector2(-h.x * 0.8, -h.y * 0.4), p + Vector2(-h.x * 0.3, -h.y), p + Vector2(h.x * 0.4, -h.y), p + Vector2(h.x, -h.y * 0.3), p + Vector2(h.x * 0.9, h.y)])
			draw_colored_polygon(body, dark)
			draw_colored_polygon(_shrink(body, p, 0.82), base)
			draw_rect(Rect2(p + Vector2(f * h.x * 0.2 - 6, -h.y * 0.6), Vector2(12, 6)), WARN)
			if e.armor_left > 0:
				for k: int in e.armor_left:
					draw_rect(Rect2(p + Vector2(-h.x + k * 14.0, -h.y - 14.0), Vector2(10, 6)), Color(0.8, 0.8, 0.85))
		&"gunner":
			draw_rect(Rect2(p - h, h * 2.0), dark)
			draw_rect(Rect2(p - h * 0.8, h * 1.6), base)
			draw_line(p + Vector2(0, -h.y * 0.3), p + Vector2(f * h.x * 2.0, -h.y * 0.3), Color(0.2, 0.2, 0.22), 7.0)
			draw_circle(p + Vector2(f * h.x * 0.3, -h.y * 0.6), 4.0, WARN)
		&"flyer":
			var flap: float = sin(t * 14.0 + e.index) * h.y
			var wing := PackedVector2Array([p, p + Vector2(-h.x * 1.6, -flap - 6), p + Vector2(-h.x * 0.4, 4), p + Vector2(h.x * 0.4, 4), p + Vector2(h.x * 1.6, -flap - 6)])
			draw_colored_polygon(wing, base if not e.grounded_fall else base.darkened(0.4))
			draw_circle(p + Vector2(f * 8.0, 0), 7.0, dark)
			if e.grounded_fall:
				draw_line(p + Vector2(-h.x, -h.y - 6), p + Vector2(h.x, -h.y - 6), Color(0.55, 0.57, 0.6), 3.0)
		&"lancer":
			var tip: Vector2 = p + Vector2(f * h.x * 1.8, 0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-f * h.x, -h.y), tip, p + Vector2(-f * h.x, h.y)]), base)
			draw_line(p, tip + Vector2(f * 30.0, 0), Color(1.6, 1.6, 1.8) if winding else WARN, 3.0)
		&"core":
			_core(e, p)
	if winding:
		var tri := PackedVector2Array([p + Vector2(0, -h.y - 34), p + Vector2(-10, -h.y - 16), p + Vector2(10, -h.y - 16)])
		draw_colored_polygon(tri, WARN)
		draw_string(UiStyle.mono(), p + Vector2(-4, -h.y - 19), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	if e.state == EnemyBase.S.LAUNCHED:
		draw_arc(p, h.length() + 8.0, 0, TAU, 28, Color(0.25, 1.8, 2.0, 0.9), 3.0)
		var c: ZenithCombat = s.zenith.combat
		if c.chase_target == e and c.chase_t > 0:
			var k: float = float(c.chase_t) / float(Tuning.t.chase_window_f + int(Run.build.add(&"chase_window_f")))
			draw_arc(p, h.length() + 12.0 + 60.0 * k, 0, TAU, 40, Color(1.0, 0.25, 0.85, 0.85), 2.0)
	if e.pin_t > 0:
		for k: int in 3:
			draw_line(p + Vector2(-h.x - 4, -h.y + k * h.y), p + Vector2(h.x + 4, -h.y + k * h.y), Color(0.6, 0.62, 0.66), 4.0)

func _core(e: EnemyBase, p: Vector2) -> void:
	var r: float = e.half.x
	var mg := Color("#FF3FD8")
	for k: int in 8:
		var a: float = t * 0.6 + k * TAU / 8.0
		var tip: Vector2 = p + Vector2(cos(a), sin(a)) * r * (1.5 + 0.15 * sin(t * 3.0 + k))
		draw_colored_polygon(PackedVector2Array([p + Vector2(cos(a - 0.3), sin(a - 0.3)) * r * 0.5, tip, p + Vector2(cos(a + 0.3), sin(a + 0.3)) * r * 0.5]), Color(0.55, 0.12, 0.45, 0.9))
	draw_circle(p, r, Color(0.3, 0.05, 0.25))
	draw_circle(p, r * 0.7, mg if e.flash_t == 0 else Color(2, 2, 2))
	draw_circle(p, r * 0.3, Color(2.0, 1.2, 1.9))
	var frac: float = e.hp / e.max_hp
	draw_arc(p, r * 1.15, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, Color(1.0, 0.8, 0.95, 0.7), 3.0)

func _shrink(poly: PackedVector2Array, c: Vector2, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in poly:
		out.append(c + (v - c) * k)
	return out
