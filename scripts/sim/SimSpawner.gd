class_name SimSpawner
extends RefCounted
## Keeps each dimension populated from its data enemy table; never inside terrain.

const U: float = 32.0

var sim: Sim
var timer: int = 0
var next_index: int = 0

func zenith_start() -> Vector2:
	var g: TerrainGrid = sim.grid
	var d: DimensionDef = Multiverse.def()
	var x: int = 20 if d.chunk_pool != &"bloom_lair" else 12
	if not d.grounded or d.is_corridor:
		return find_free(Vector2((x + 0.5) * U, g.h * U * 0.5))
	for y: int in range(2, g.h):
		if g.get_cell(x, y) == TerrainGrid.SOLID:
			return Vector2((x + 0.5) * U, y * U - 31.0)
	return Vector2(x * U, 10 * U)

func find_free(p: Vector2) -> Vector2:
	var half: Vector2 = Vector2(16, 32)
	for k: int in 40:
		var q: Vector2 = p + Vector2(0, -k * 16.0)
		if not sim.grid.rect_blocked(q, half):
			return sim.grid.wrap_pos(q)
	return p

func target_count() -> int:
	var d: DimensionDef = Multiverse.def()
	var n: int = d.enemy_target
	if Run.clock.overflow:
		n = int(n * 1.6)
	return n

func initial_fill() -> void:
	timer = 60
	var n: int = mini(target_count(), 6)
	for i: int in n:
		_spawn_random(false)

func step() -> void:
	if Multiverse.def().enemy_table.is_empty() and not Multiverse.def().is_corridor:
		return
	timer -= 1
	if timer > 0:
		return
	timer = 45 if Run.clock.overflow else 90
	if sim.is_corridor():
		if sim.live_enemies() < 2 and sim.corridor_progress > 60.0 and sim.corridor_progress < 150.0:
			spawn_near(&"drone")
		return
	if sim.live_enemies() < target_count():
		_spawn_random(true)

func hp_mul(dim_band: int) -> float:
	var f: float = Run.clock.life_fraction()
	var m: float = (1.0 + 0.9 * pow(f, 1.2)) * (1.0 + 0.5 * float(dim_band - 1))
	if dim_band > Run.player_band():
		m *= Tuning.prog.above_hp_mul
	return m

func _spawn_random(away: bool) -> void:
	var d: DimensionDef = Multiverse.def()
	if d.enemy_table.is_empty():
		return
	var id: StringName = StringName(d.enemy_table[Run.rng.randi_range(0, d.enemy_table.size() - 1)])
	if id == &"flyer":
		var flock: int = 3 if Run.clock.life_fraction() < 0.3 else 5
		var anchor: Vector2 = _pick_spot(away)
		for i: int in flock:
			_spawn_at(id, anchor + Vector2(i * 40.0 - 80.0, (i % 2) * 30.0))
		return
	_spawn_at(id, _pick_spot(away))

func _pick_spot(away: bool) -> Vector2:
	var spots: Array[Vector2] = sim.built.spawns
	if spots.is_empty():
		return sim.zenith.pos + Vector2(20 * U, -4 * U)
	for tries: int in 12:
		var p: Vector2 = spots[Run.rng.randi_range(0, spots.size() - 1)]
		var dist: float = sim.grid.delta(sim.zenith.pos, p).length()
		if not away or (dist > 18.0 * U and dist < 70.0 * U):
			return p
	return spots[Run.rng.randi_range(0, spots.size() - 1)]

func spawn_near(id: StringName) -> EnemyBase:
	var dir: float = 1.0 if Run.rng.randf() < 0.5 else -1.0
	var p: Vector2 = sim.zenith.pos + Vector2(dir * Run.rng.randf_range(12.0, 22.0) * U, -Run.rng.randf_range(1.0, 5.0) * U)
	return _spawn_at(id, p)

func _spawn_at(id: StringName, p: Vector2) -> EnemyBase:
	var def: EnemyDef = Tuning.enemy(id)
	if def == null:
		return null
	var half: Vector2 = def.size * U * 0.5
	p = sim.grid.wrap_pos(p)
	var tries: int = 0
	while sim.grid.rect_blocked(p, half) and tries < 30:
		p.y -= 16.0
		tries += 1
	if sim.grid.rect_blocked(p, half):
		return null
	for e: EnemyBase in sim.enemies:
		if not e.alive:
			var band: int = Multiverse.band_of(Multiverse.current)
			e.spawn(sim, def, p, hp_mul(band), next_index)
			e.band = band
			next_index += 1
			if id == &"flyer" and Multiverse.marked.has(&"skyreach") and Multiverse.current == &"skyreach" and Run.adaptations.has(&"weight"):
				e.grounded_fall = true
			return e
	return null
