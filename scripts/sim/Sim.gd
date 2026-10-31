class_name Sim
extends Node2D
## The fixed-step gameplay world. One `step()` per 60 Hz tick. Presentation nodes
## read this and listen to Events; they never write to it.

const U: float = 32.0
const DT: float = 1.0 / 60.0
const MAX_ENEMIES: int = 72

var grid: TerrainGrid
var built: ChunkAssembler.Built
var zenith: Zenith
var enemies: Array[EnemyBase] = []
var bolts: Array[Dictionary] = []
var echoes: Array[Dictionary] = []
var craters: Array[Vector2] = []
var props: Array[Rect2] = []
var tokens: AttackTokens = AttackTokens.new()
var spawner: SimSpawner = SimSpawner.new()
var bloom: Bloom = null
var director: RefCounted = null
var chain: int = 0
var chain_t: int = 0
var prev_held: int = 0
var map_open: bool = false
var map_acc: float = 0.0
var corridor_progress: float = 0.0
var split_points: Array = []
var built_generation: int = -1
var spawning_enabled: bool = true
var world_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	zenith = Zenith.new()
	zenith.name = "Zenith"
	add_child(zenith)
	for i: int in MAX_ENEMIES:
		var e := EnemyBase.new()
		e.name = "E%d" % i
		e.visible = false
		add_child(e)
		enemies.append(e)
	spawner.sim = self
	Run.sim = self

func _exit_tree() -> void:
	if Run.sim == self:
		Run.sim = null

func is_corridor() -> bool:
	return Multiverse.def().is_corridor

func rebuild() -> void:
	built_generation = Multiverse.generation
	var d: DimensionDef = Multiverse.def()
	built = ChunkAssembler.build(d, Run.rng)
	grid = built.grid
	props = built.props.duplicate()
	craters.clear()
	bolts.clear()
	echoes.clear()
	tokens.clear()
	for e: EnemyBase in enemies:
		e.alive = false
		e.visible = false
	zenith.buffer.clear()
	corridor_progress = 0.0
	chain = 0
	bloom = null
	if d.id == &"bloom_lair" and not Run.clock.threat_ended:
		bloom = Bloom.new()
		bloom.setup(self)
	var start: Vector2 = spawner.zenith_start()
	if zenith.sim == null:
		zenith.setup(self, start)
	else:
		zenith.pos = start
		zenith.vel = Vector2.ZERO
		zenith.combat.cancel()
		zenith.state = Zenith.S.NEUTRAL
	spawner.initial_fill()

## Reads live input (or the replay log) for this tick and advances the world.
func step_with_packed(v: int) -> void:
	var inp: SimInput = SimInput.from_packed(v, prev_held)
	prev_held = inp.held
	step(inp)

func step(inp: SimInput) -> void:
	if not Run.active and Run.clock.phase != RunClock.Phase.FADED:
		return
	Run.apply_logged_commands()
	if built_generation != Multiverse.generation:
		rebuild()
	if Run.is_frozen():
		return
	if not Run.is_replay():
		Run.input_log.frames.append(InputLog.pack(inp.held, inp.move))
	Run.tick += 1
	if map_open:
		map_acc += Tuning.t.map_time_scale
		if map_acc < 1.0:
			return
		map_acc -= 1.0
	if Run.hitstop > 0:
		Run.hitstop -= 1
		zenith.step_buffer_only(inp)
		return
	var rate: float = Multiverse.def().clock_rate
	Run.clock.tick(DT * rate)
	if not Run.active:
		return
	Multiverse.tick_threat(Run.clock.elapsed())
	if built_generation != Multiverse.generation:
		rebuild()
		return
	zenith.step(inp)
	for e: EnemyBase in enemies:
		if e.alive:
			e.step()
	SimCombat.step_bolts(self)
	SimCombat.step_echoes(self)
	if bloom:
		bloom.step(inp)
	if director:
		director.step()
	if spawning_enabled:
		spawner.step()
	_weight_aura()
	_corridor()
	if chain_t > 0:
		chain_t -= 1
		if chain_t == 0:
			break_chain()
	Run.sample_power()

func _weight_aura() -> void:
	if Multiverse.current != &"skyreach" or not Run.adaptations.has(&"weight"):
		return
	for e: EnemyBase in enemies:
		if e.alive and not e.grounded_fall and e.def.behavior == &"flyer":
			if grid.delta(zenith.pos, e.pos).length() <= 12.0 * U:
				e.grounded_fall = true
				e.flash_t = 8

func _corridor() -> void:
	if not is_corridor():
		return
	corridor_progress += maxf(0.0, zenith.vel.x) * DT / U
	if corridor_progress >= 200.0:
		Multiverse.arrive_from_corridor()

func break_chain() -> void:
	if chain > 0:
		chain = 0
		Events.chain_changed.emit(0)

func on_hit_landed(e: EnemyBase, h: Dictionary) -> void:
	SimCombat.on_hit_landed(self, e, h)

func on_chase(e: EnemyBase) -> void:
	if director:
		director.on_chase(e)

func kill_enemy(e: EnemyBase, reward: bool = true) -> void:
	SimCombat.kill(self, e, reward)

func live_enemies() -> int:
	var n: int = 0
	for e: EnemyBase in enemies:
		if e.alive:
			n += 1
	return n

func enemies_in_rect(r: Rect2) -> Array:
	var out: Array = []
	for e: EnemyBase in enemies:
		if not e.alive:
			continue
		var c: Vector2 = r.get_center() + grid.delta(r.get_center(), e.pos)
		if Rect2(c - e.half, e.half * 2.0).intersects(r):
			out.append(e)
	return out

func enemies_in_radius(p: Vector2, r: float) -> Array:
	var out: Array = []
	for e: EnemyBase in enemies:
		if e.alive and grid.delta(p, e.pos).length() <= r + e.half.length() * 0.6:
			out.append(e)
	return out

func nearest_target(p: Vector2, r: float) -> EnemyBase:
	var best: EnemyBase = null
	var bd: float = r
	for e: EnemyBase in enemies:
		if not e.alive:
			continue
		var d: float = grid.delta(p, e.pos).length()
		if d < bd:
			bd = d
			best = e
	return best

func zenith_overlaps(p: Vector2, half_ext: Vector2) -> bool:
	var d: Vector2 = grid.delta(p, zenith.pos)
	return absf(d.x) < half_ext.x + zenith.half.x and absf(d.y) < half_ext.y + zenith.half.y

func band_damage_mul() -> float:
	if Multiverse.band_of(Multiverse.current) > Run.player_band():
		return Tuning.prog.above_damage_mul
	return 1.0

func beam_damage(origin: Vector2, dir: Vector2, length: float, width: float, dmg: float, skip: Object = null) -> EnemyBase:
	return SimCombat.beam_damage(self, origin, dir, length, width, dmg, skip)

func launched_collisions(e: EnemyBase) -> void:
	SimCombat.launched_collisions(self, e)

func spawn_enemy_near(id: StringName) -> EnemyBase:
	return spawner.spawn_near(id)

func spawn_bolt(p: Vector2, v: Vector2, friendly: bool, dmg: float) -> void:
	bolts.append({"pos": p, "vel": v, "friendly": friendly, "dmg": dmg, "life": 150})

func reflect_bolts(p: Vector2, r: float) -> void:
	for b: Dictionary in bolts:
		if not b["friendly"] and grid.delta(p, b["pos"]).length() <= r:
			b["friendly"] = true
			b["vel"] = -b["vel"] * 1.4
			b["dmg"] = Tuning.t.volley_damage * 2.0 * Run.power()

func clear_bolts(p: Vector2, r: float) -> void:
	bolts = bolts.filter(func(b: Dictionary) -> bool: return b["friendly"] or grid.delta(p, b["pos"]).length() > r)

func spawn_echo(p: Vector2) -> void:
	echoes.append({"pos": p, "t": 30})

func add_crater(p: Vector2) -> void:
	craters.append(p)
	if craters.size() > 40:
		craters.pop_front()

func enemy_area_attack(e: EnemyBase, r: float, heavy: bool) -> void:
	if grid.delta(e.pos, zenith.pos).length() <= r + zenith.half.y:
		zenith.receive_attack(e.pos, heavy, e.boss_part, band_damage_mul())
