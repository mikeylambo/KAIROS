class_name FxLayer
extends Node2D
## Pooled VFX driven by data recipes (fx_recipes.tres) and Events. Presentation only.

const U: float = 32.0
const MAX_P: int = 900

var cam: GameCamera
var parts: Array[Dictionary] = []   # sparks/shards/motes
var rings: Array[Dictionary] = []
var lines: Array[Dictionary] = []   # speed lines
var ghosts: Array[Dictionary] = []  # afterimages
var cracks: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var ghost_tick: int = 0

func _ready() -> void:
	rng.seed = 99
	Events.hit_landed.connect(func(p: Vector2, kind: StringName, _d: float, _c: int) -> void:
		burst(&"spark_l" if kind == &"heavy" else (&"spark_m" if kind == &"collide" else &"spark_s"), p))
	Events.launched.connect(_on_launch)
	Events.transmitted.connect(_on_transmit)
	Events.perfect_guard.connect(func(p: Vector2) -> void:
		burst(&"guard_chime", p)
		_ghost_at(p, Color(1, 1, 1, 0.8), 0.5))
	Events.zenith_hit.connect(func(p: Vector2, _c: float) -> void: burst(&"time_shard", p))
	Events.field_fired.connect(func(p: Vector2, r: float) -> void:
		rings.append({"pos": p, "r0": 10.0, "r1": r, "t": 0.0, "life": 0.35, "col": Color(2.0, 1.4, 2.2), "w": 10.0}))
	Events.beam_ended.connect(func(p: Vector2, fin: bool) -> void:
		if fin:
			burst(&"beam_impact", p))
	Events.enemy_killed.connect(func(p: Vector2, id: StringName) -> void:
		burst(&"feathers" if id == &"flyer" else (&"bloom_burst" if id == &"bloom_core" or id == &"bloom_spore" else &"spark_m"), p))
	Events.terrain_impact.connect(func(p: Vector2) -> void:
		burst(&"dust", p)
		cracks.append({"pos": p, "t": 0.0, "seed": rng.randi()}))
	Events.world_break.connect(_shatter)
	Events.dimension_marked.connect(func(_id: StringName) -> void:
		if cam and cam.sim:
			_shatter(cam.sim.zenith.pos))

func burst(id: StringName, p: Vector2) -> void:
	var r: FxRecipe = Tuning.fx.get_recipe(id)
	if r == null:
		return
	if r.family == &"ring":
		rings.append({"pos": p, "r0": 6.0, "r1": 70.0 * r.size.y / 4.0, "t": 0.0, "life": r.lifetime, "col": r.colors[0] * 1.8, "w": 3.0})
		return
	for i: int in r.count:
		if parts.size() >= MAX_P:
			parts.pop_front()
		var a: float = rng.randf() * TAU
		var sp: float = rng.randf_range(r.speed.x, r.speed.y) * U
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * sp, "t": 0.0, "life": r.lifetime * rng.randf_range(0.7, 1.2),
			"size": rng.randf_range(r.size.x, r.size.y), "col": r.colors[i % r.colors.size()] * 1.5, "kind": 0})

func _on_launch(p: Vector2, dir: Vector2) -> void:
	for i: int in 22:
		var off: Vector2 = dir.orthogonal() * rng.randf_range(-260, 260)
		lines.append({"pos": p + off - dir * rng.randf_range(0, 300), "dir": dir, "t": 0.0, "life": 0.22, "len": rng.randf_range(200, 600)})

func _on_transmit(a: Vector2, b: Vector2, chase: bool) -> void:
	_ghost_at(a, Color(0.25, 0.96, 1.0, 0.75), 0.35)
	rings.append({"pos": b, "r0": 70.0, "r1": 8.0, "t": 0.0, "life": 0.22, "col": Color(0.6, 2.0, 2.2), "w": 3.0})
	if chase:
		rings.append({"pos": b, "r0": 8.0, "r1": 120.0, "t": 0.0, "life": 0.3, "col": Color(2.2, 0.6, 1.9), "w": 2.0})

func _ghost_at(p: Vector2, col: Color, life: float) -> void:
	var z: Zenith = cam.sim.zenith if cam and cam.sim else null
	ghosts.append({"pos": p, "t": 0.0, "life": life, "col": col, "facing": z.facing if z else 1})

func _shatter(p: Vector2) -> void:
	for i: int in 26:
		var a: float = rng.randf() * TAU
		parts.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * rng.randf_range(200, 900), "t": 0.0, "life": rng.randf_range(0.5, 1.0),
			"size": rng.randf_range(6, 16), "col": Color(0.8, 0.95, 1.0, 0.9), "kind": 1, "rot": rng.randf() * TAU})

func _process(delta: float) -> void:
	if cam and cam.sim and cam.sim.zenith:
		var z: Zenith = cam.sim.zenith
		ghost_tick += 1
		if z.afterimage_ticks > 0 and ghost_tick % 2 == 0:
			var col: Color = Color(0.25, 0.96, 1.0, 0.55) if (ghost_tick / 2) % 2 == 0 else Color(1.0, 0.25, 0.85, 0.55)
			ghosts.append({"pos": z.pos, "t": 0.0, "life": 0.25, "col": col, "facing": z.facing})
	for p: Dictionary in parts:
		p["t"] = float(p["t"]) + delta
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["vel"] = (p["vel"] as Vector2) * (1.0 - 4.0 * delta)
	parts = parts.filter(func(p: Dictionary) -> bool: return float(p["t"]) < float(p["life"]))
	for arr: Array in [rings, lines, ghosts, cracks]:
		for d: Dictionary in arr:
			d["t"] = float(d["t"]) + delta
	rings = rings.filter(func(d: Dictionary) -> bool: return float(d["t"]) < float(d["life"]))
	lines = lines.filter(func(d: Dictionary) -> bool: return float(d["t"]) < float(d["life"]))
	ghosts = ghosts.filter(func(d: Dictionary) -> bool: return float(d["t"]) < float(d["life"]))
	cracks = cracks.filter(func(d: Dictionary) -> bool: return float(d["t"]) < 3.0)
	queue_redraw()

func _draw() -> void:
	if cam == null or cam.sim == null:
		return
	for c: Dictionary in cracks:
		var p0: Vector2 = cam.vp(c["pos"])
		var a: float = 1.0 - float(c["t"]) / 3.0
		var r2 := RandomNumberGenerator.new()
		r2.seed = int(c["seed"])
		for k: int in 7:
			var ang: float = r2.randf() * TAU
			var len: float = r2.randf_range(20, 60)
			var mid: Vector2 = p0 + Vector2(cos(ang), sin(ang)) * len * 0.5 + Vector2(r2.randf_range(-6, 6), r2.randf_range(-6, 6))
			draw_polyline(PackedVector2Array([p0, mid, p0 + Vector2(cos(ang), sin(ang)) * len]), Color(1, 1, 1, 0.5 * a), 1.5)
	for g: Dictionary in ghosts:
		var p: Vector2 = cam.vp(g["pos"])
		var k: float = 1.0 - float(g["t"]) / float(g["life"])
		var col: Color = g["col"]
		col.a *= k
		var f: float = float(g["facing"])
		draw_colored_polygon(PackedVector2Array([p + Vector2(-8 * f, -34), p + Vector2(8 * f, -34), p + Vector2(10 * f, -8), p + Vector2(7 * f, 30), p + Vector2(-7 * f, 30), p + Vector2(-9 * f, -8)]), col)
		draw_circle(p + Vector2(f, -31), 7.0, col)
	for l: Dictionary in lines:
		var k2: float = 1.0 - float(l["t"]) / float(l["life"])
		var p2: Vector2 = cam.vp(l["pos"]) + (l["dir"] as Vector2) * float(l["t"]) * 2400.0
		draw_line(p2, p2 + (l["dir"] as Vector2) * float(l["len"]), Color(1.6, 1.8, 2.0, 0.55 * k2), 2.0)
	for r: Dictionary in rings:
		var k3: float = float(r["t"]) / float(r["life"])
		var rad: float = lerpf(float(r["r0"]), float(r["r1"]), 1.0 - pow(1.0 - k3, 3.0))
		var col2: Color = r["col"]
		col2.a = 1.0 - k3
		draw_arc(cam.vp(r["pos"]), rad, 0, TAU, 48, col2, float(r["w"]) * (1.0 - k3 * 0.6))
	for p3: Dictionary in parts:
		var k4: float = 1.0 - float(p3["t"]) / float(p3["life"])
		var pos: Vector2 = cam.vp(p3["pos"])
		var col3: Color = p3["col"]
		col3.a *= k4
		if int(p3["kind"]) == 1:
			var s: float = float(p3["size"])
			var rot: float = float(p3["rot"]) + float(p3["t"]) * 6.0
			draw_colored_polygon(PackedVector2Array([pos + Vector2(s, 0).rotated(rot), pos + Vector2(-s * 0.5, s * 0.6).rotated(rot), pos + Vector2(-s * 0.4, -s * 0.7).rotated(rot)]), col3)
		else:
			var v: Vector2 = (p3["vel"] as Vector2) * 0.03
			draw_line(pos - v, pos + v, col3, float(p3["size"]) * k4 + 1.0)
