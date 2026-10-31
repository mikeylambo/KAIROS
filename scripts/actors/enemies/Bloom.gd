class_name Bloom
extends RefCounted
## The Bloom, first-run threat. Phase 1: vine walls + spore volleys. Phase 2: three
## cores to chase between. Phase 3: beam clash; win → finisher → threat ended.

const U: float = 32.0

var sim: Sim
var phase: int = 0
var cores: Array[EnemyBase] = []
var vines: Array[Dictionary] = []  # {x, t, active}
var vine_timer: int = 120
var spore_timer: int = 160
var clash: float = 50.0
var clash_cool: int = 0
var finisher_t: int = 0
var hp_scale: float = 1.0
var core_def: EnemyDef

func setup(s: Sim) -> void:
	sim = s
	hp_scale = clampf(Run.clock.start / Tuning.t.clock_start, 0.08, 1.0)
	core_def = EnemyDef.new()
	core_def.id = &"bloom_core"
	core_def.display_name = "The Bloom"
	core_def.behavior = &"core"
	core_def.flies = true
	core_def.size = Vector2(4.0, 4.0)
	core_def.xp = 400.0
	core_def.color = Color("#d94fb8")
	_enter_phase(1)

func _make_core(p: Vector2, hp: float, size: float) -> EnemyBase:
	var d: EnemyDef = core_def.duplicate()
	d.hp = hp
	d.size = Vector2(size, size)
	for e: EnemyBase in sim.enemies:
		if not e.alive:
			e.spawn(sim, d, p, 1.0, 900 + cores.size())
			e.boss_part = true
			e.state = EnemyBase.S.RECOVER
			e.state_t = 999999
			cores.append(e)
			return e
	return null

func _enter_phase(n: int) -> void:
	phase = n
	cores.clear()
	var w: float = sim.grid.w * U
	var hp: PackedFloat32Array = Tuning.threat.phase_hp
	match n:
		1:
			_make_core(Vector2(w * 0.5, 9.0 * U), hp[0] * hp_scale * 6.0, 4.0)
		2:
			for p: Vector2 in [Vector2(w * 0.18, 14.0 * U), Vector2(w * 0.5, 7.0 * U), Vector2(w * 0.82, 14.0 * U)]:
				_make_core(p, Tuning.threat.core_hp * hp_scale * 5.0, 2.6)
		3:
			clash = 50.0
			clash_cool = 0
	Events.bloom_phase.emit(n)

func on_core_killed(_e: EnemyBase) -> void:
	for c: EnemyBase in cores:
		if c.alive:
			return
	Events.world_break.emit(_e.pos)
	Run.request_hitstop(12)
	_enter_phase(phase + 1)

func step(inp: SimInput) -> void:
	if phase == 0 or Run.clock.threat_ended:
		return
	for c: EnemyBase in cores:
		if c.alive:
			c.state = EnemyBase.S.RECOVER
			c.state_t = 999999
			c.vel = Vector2(0, sin(c.anim_t * 1.5 + c.index) * 18.0)
	if phase == 3:
		_clash(inp)
		return
	_vines()
	spore_timer -= 1
	if spore_timer <= 0:
		spore_timer = 200 if phase == 1 else 260
		for i: int in 3:
			var src: EnemyBase = cores[i % cores.size()] if not cores.is_empty() else null
			if src and src.alive:
				var e: EnemyBase = sim.spawner._spawn_at(&"bloom_spore", src.pos + Vector2((i - 1) * 40.0, 60.0))
				if e:
					e.state = EnemyBase.S.APPROACH

func _vines() -> void:
	vine_timer -= 1
	if vine_timer <= 0:
		vine_timer = 150 if phase == 1 else 190
		vines.append({"x": sim.zenith.pos.x, "t": Tuning.threat.telegraph_f, "active": 30, "hit": false})
		Events.enemy_windup.emit(Vector2(sim.zenith.pos.x, sim.zenith.pos.y))
	var keep: Array[Dictionary] = []
	for v: Dictionary in vines:
		if int(v["t"]) > 0:
			v["t"] = int(v["t"]) - 1
			keep.append(v)
			continue
		v["active"] = int(v["active"]) - 1
		if not v["hit"] and absf(sim.grid.delta(Vector2(v["x"], 0), sim.zenith.pos).x) < 1.2 * U + sim.zenith.half.x:
			v["hit"] = true
			sim.zenith.receive_attack(Vector2(v["x"], sim.zenith.pos.y), true, true, 1.0)
		if int(v["active"]) > 0:
			keep.append(v)
	vines = keep

func _clash(inp: SimInput) -> void:
	if finisher_t > 0:
		finisher_t -= 1
		if finisher_t == 0:
			Run.end_threat()
		return
	if clash_cool > 0:
		clash_cool -= 1
		return
	var z: Zenith = sim.zenith
	if inp.is_pressed(InputLog.B_KI) or inp.is_pressed(InputLog.B_LIGHT):
		clash += Tuning.threat.clash_per_press
	elif inp.is_held(InputLog.B_KI):
		clash += 0.5
	clash -= Tuning.threat.clash_drain / 60.0 * (0.6 + 0.4 * (1.0 / Run.power()))
	z.state = Zenith.S.BEAM_FIRE
	z.state_t = 2
	z.combat.beam_frac = 1.0
	z.combat.beam_dir = sim.grid.delta(z.pos, clash_point()).normalized()
	Events.clash_changed.emit(clash)
	if clash >= Tuning.threat.clash_need:
		finisher_t = 40
		z.state = Zenith.S.RECOVER
		z.state_t = 40
		Run.request_hitstop(Tuning.t.beam_hitstop_f)
		Events.beam_ended.emit(z.pos, true)
		Events.flash.emit(1.0)
		Events.shake.emit(10.0)
	elif clash <= 0.0:
		z.state = Zenith.S.NEUTRAL
		z.receive_attack(clash_point(), true, true, 1.0)
		clash = 50.0
		clash_cool = 90

func clash_point() -> Vector2:
	return Vector2(sim.grid.w * U * 0.5, 9.0 * U)
