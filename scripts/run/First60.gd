class_name First60
extends RefCounted
## GDD §9, scripted: push-in + line, three drones (J/X glyph), heavy drone (K/Y →
## L/B on the flying target), billboard break, 8-drone wave (U/RT once at ki ≥ 40),
## exposure meter + map pulse at 0:50. Glyphs never reappear after success.
## Beat times are boot-relative: run start = 0:04 (title is player-paced).

const U: float = 32.0
const BOOT_OFFSET: float = 4.0
const BEATS: Dictionary = {&"push_in": 4.0, &"drones": 7.0, &"heavy": 15.0, &"first_chase": 19.0,
	&"billboard": 25.0, &"wave": 35.0, &"map_pulse": 50.0}

var sim: Sim
var hud: Hud
var fired: Dictionary = {}  # beat -> boot-time seconds
var heavy_enemy: EnemyBase = null
var first_drone: EnemyBase = null
var ki_glyph_done: bool = false
var light_glyph_done: bool = false
var launch_glyph: bool = false
var finished: bool = false
var chased: bool = false
var billboard_placed: bool = false
const BILLBOARD_AT: float = 23.0

func setup(s: Sim, h: Hud) -> void:
	sim = s
	hud = h
	sim.spawning_enabled = false
	for e: EnemyBase in sim.enemies:
		e.alive = false
		e.visible = false
	if hud:
		hud.exposure_visible = false
	Events.hit_landed.connect(_on_hit)
	Events.launched.connect(_on_launch)
	Events.world_break.connect(_on_break)
	Events.beam_started.connect(_on_beam)

func teardown() -> void:
	for pair: Array in [[Events.hit_landed, _on_hit], [Events.launched, _on_launch], [Events.world_break, _on_break], [Events.beam_started, _on_beam]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])

func _on_break(_p: Vector2) -> void:
	if billboard_placed:
		_beat(&"billboard")

func _on_beam(_p: Vector2) -> void:
	if hud:
		hud.clear_glyph(&"ki")

func now() -> float:
	return float(Run.tick) / 60.0 + BOOT_OFFSET

func _beat(b: StringName) -> void:
	if fired.has(b):
		return
	fired[b] = now()
	Events.tutorial_beat.emit(b)

func _glyph(id: StringName, kbm: String, pad: String, target: Object) -> void:
	if hud:
		hud.add_glyph(pad if Input.get_connected_joypads().size() > 0 else kbm, target, id)

func step() -> void:
	if finished:
		return
	var t: float = now()
	if not fired.has(&"push_in"):
		_beat(&"push_in")
		Events.line_spoken.emit("Thirty minutes. Plenty.")
		Audio.voice(&"voice_zenith_line")
		if sim.zenith:
			sim.zenith.afterimage_ticks = 10
	if t >= BEATS[&"drones"] and not fired.has(&"drones"):
		_beat(&"drones")
		for i: int in 3:
			var e: EnemyBase = sim.spawner._spawn_at(&"drone", sim.zenith.pos + Vector2((9 + i * 3) * U, -1.5 * U - i * 12.0))
			if i == 0:
				first_drone = e
		_glyph(&"light", "J", "X", first_drone)
	if t >= BEATS[&"heavy"] and not fired.has(&"heavy"):
		_beat(&"heavy")
		heavy_enemy = sim.spawner._spawn_at(&"brute", sim.zenith.pos + Vector2(8 * U, -2 * U))
		if heavy_enemy:
			heavy_enemy.max_hp = 900.0
			heavy_enemy.hp = 900.0
		_glyph(&"heavy", "K", "Y", heavy_enemy)
	if chased and not billboard_placed and t >= BILLBOARD_AT:
		_place_billboard()
	if t >= BEATS[&"wave"] and not fired.has(&"wave"):
		_beat(&"wave")
		for i: int in 8:
			var side: float = 1.0 if i % 2 == 0 else -1.0
			sim.spawner._spawn_at(&"drone", sim.zenith.pos + Vector2(side * (10 + i) * U, -(2 + i % 3) * U))
	if fired.has(&"wave") and not ki_glyph_done and sim.zenith.ki >= Tuning.t.ki_beam:
		ki_glyph_done = true
		_glyph(&"ki", "U", "RT", null)
	if t >= BEATS[&"map_pulse"] and not fired.has(&"map_pulse"):
		_beat(&"map_pulse")
		if hud:
			hud.exposure_visible = true
			hud.map_pulse = 4.0
			hud.clear_glyph(&"ki")
		sim.spawning_enabled = true
		finished = true

func _on_hit(_p: Vector2, kind: StringName, _d: float, _c: int) -> void:
	if not light_glyph_done and kind == &"light" and hud:
		light_glyph_done = true
		hud.clear_glyph(&"light")

func _on_launch(_p: Vector2, _dir: Vector2) -> void:
	if hud:
		hud.clear_glyph(&"heavy")
	var c: ZenithCombat = sim.zenith.combat
	if c.chase_target != null and not launch_glyph:
		launch_glyph = true
		_glyph(&"chase", "L", "B", c.chase_target)

func on_chase(e: EnemyBase) -> void:
	if hud:
		hud.clear_glyph(&"chase")
	if not fired.has(&"first_chase"):
		_beat(&"first_chase")
		chased = true

## The billboard arrives in front of the current target so the next hit sends it
## through (world reacts). Paced to ≥ 0:23 so the beat lands near 0:25.
func _place_billboard() -> void:
	billboard_placed = true
	var e: EnemyBase = heavy_enemy if heavy_enemy != null and heavy_enemy.alive else null
	if e == null:
		e = sim.spawner._spawn_at(&"drone", sim.zenith.pos + Vector2(float(sim.zenith.facing) * 2.5 * U, -1.0 * U))
	if e == null:
		return
	var side: float = signf(sim.grid.delta(sim.zenith.pos, e.pos).x)
	if side == 0.0:
		side = float(sim.zenith.facing)
	var at: Vector2 = e.pos + Vector2(side * 1.0 * U, 0)
	sim.props.append(Rect2(at - Vector2(0 if side > 0 else 5 * U, 2.5 * U), Vector2(5, 4) * U))
