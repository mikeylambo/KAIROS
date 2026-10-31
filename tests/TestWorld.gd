class_name TestWorld
extends RefCounted
## Builds a deterministic sim for tests. flat=true replaces terrain with a flat
## floor (top row 30) so movement numbers are measured cleanly.

const U: float = 32.0
const FLOOR_Y: float = 30.0 * 32.0

static func make(parent: Node, seed_v: int = 1, clock: float = 1800.0, flat: bool = true, cfg: Dictionary = {}) -> Sim:
	Profile.persist = false
	var c: Dictionary = {"seed": seed_v, "clock": clock}
	c.merge(cfg, true)
	Run.start_run(c)
	var sim := Sim.new()
	parent.add_child(sim)
	sim.step_with_packed(InputLog.pack(0, Vector2.ZERO))
	if flat:
		var g := TerrainGrid.new()
		g.setup(200, 34)
		g.wrap_x = true
		g.fill(0, 30, 200, 4, TerrainGrid.SOLID)
		sim.grid = g
		sim.built.grid = g
		sim.props.clear()
		sim.zenith.pos = Vector2(40 * U, FLOOR_Y - sim.zenith.half.y)
		sim.zenith.vel = Vector2.ZERO
	clear_enemies(sim)
	sim.spawning_enabled = false
	return sim

static func clear_enemies(sim: Sim) -> void:
	for e: EnemyBase in sim.enemies:
		e.alive = false
	sim.tokens.clear()

static func dummy(sim: Sim, id: StringName, offset: Vector2, hp: float = -1.0) -> EnemyBase:
	var e: EnemyBase = sim.spawner._spawn_at(id, sim.zenith.pos + offset)
	e.cooldown = 1000000
	e.state = EnemyBase.S.RECOVER
	e.state_t = 1000000
	if hp > 0.0:
		e.max_hp = hp
		e.hp = hp
	return e

static func step(sim: Sim, n: int, buttons: int = 0, mv: Vector2 = Vector2.ZERO) -> void:
	for i: int in n:
		sim.step_with_packed(InputLog.pack(buttons, mv))

static func tap(sim: Sim, buttons: int, mv: Vector2 = Vector2.ZERO) -> void:
	sim.step_with_packed(InputLog.pack(buttons, mv))
