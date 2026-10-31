class_name SimCombat
extends RefCounted
## Hit bookkeeping, kills, bolts, echo mines, launched-body collisions, beam.

const U: float = 32.0

static func on_hit_landed(s: Sim, e: EnemyBase, h: Dictionary) -> void:
	s.chain += 1
	s.chain_t = 90
	Run.note_chain(s.chain)
	Events.chain_changed.emit(s.chain)
	Multiverse.add_exposure(Tuning.prog.exposure_per_hit)
	Events.hit_landed.emit(e.pos, h.get("kind", &"light"), float(h.get("damage", 0.0)), s.chain)
	break_props(s, e)

static func break_props(s: Sim, e: EnemyBase) -> void:
	for i: int in range(s.props.size() - 1, -1, -1):
		var r: Rect2 = s.props[i]
		var c: Vector2 = r.get_center() + s.grid.delta(r.get_center(), e.pos)
		if r.intersects(Rect2(c - e.half, e.half * 2.0)):
			s.props.remove_at(i)
			Events.world_break.emit(r.get_center())
			Events.shake.emit(5.0)

static func kill(s: Sim, e: EnemyBase, reward: bool) -> void:
	if not e.alive:
		return
	e.alive = false
	e.visible = false
	e.state = EnemyBase.S.DEAD
	s.tokens.release(e)
	if s.zenith.state == Zenith.S.BEAM_FIRE:
		s.zenith.combat.beam_killed = true
	if e.boss_part and s.bloom:
		s.bloom.on_core_killed(e)
	if reward:
		Run.stats["kills"] = int(Run.stats["kills"]) + 1
		Run.add_kill_xp(e.def.xp, Multiverse.band_of(Multiverse.current))
		Multiverse.add_exposure(Tuning.prog.exposure_per_kill)
	Events.enemy_killed.emit(e.pos, e.def.id)

static func step_bolts(s: Sim) -> void:
	var keep: Array[Dictionary] = []
	for b: Dictionary in s.bolts:
		b["pos"] = s.grid.wrap_pos(b["pos"] + b["vel"] / 60.0)
		b["life"] = int(b["life"]) - 1
		var dead: bool = int(b["life"]) <= 0 or s.grid.solid_at_px(b["pos"])
		if not dead and b["friendly"]:
			for e: EnemyBase in s.enemies_in_radius(b["pos"], 10.0):
				var h: Dictionary = {"damage": b["dmg"], "kind": &"bolt", "dir": (b["vel"] as Vector2).normalized(),
					"launch": false, "launch_speed": 0.0, "hitstun": 10, "pin": 0, "crush": Run.build.mul(&"crush"), "src": b["pos"]}
				if e.take_hit(h):
					s.zenith.add_ki(Tuning.t.ki_per_hit * 0.25 * Run.build.mul(&"ki_gain"))
					on_hit_landed(s, e, h)
				dead = true
				break
		elif not dead and s.zenith_overlaps(b["pos"], Vector2(8, 8)):
			s.zenith.receive_attack(b["pos"], true, false, s.band_damage_mul())
			dead = true
		if not dead:
			keep.append(b)
	s.bolts = keep

static func step_echoes(s: Sim) -> void:
	var keep: Array[Dictionary] = []
	for m: Dictionary in s.echoes:
		m["t"] = int(m["t"]) - 1
		if int(m["t"]) <= 0:
			for e: EnemyBase in s.enemies_in_radius(m["pos"], 4.0 * U):
				var h: Dictionary = {"damage": 60.0 * Run.power(), "kind": &"echo", "dir": s.grid.delta(m["pos"], e.pos).normalized(),
					"launch": false, "launch_speed": 0.0, "hitstun": 24, "pin": 0, "crush": 1.0, "src": m["pos"]}
				if e.take_hit(h):
					on_hit_landed(s, e, h)
			Events.field_fired.emit(m["pos"], 4.0 * U)
		else:
			keep.append(m)
	s.echoes = keep

static func launched_collisions(s: Sim, e: EnemyBase) -> void:
	for o: EnemyBase in s.enemies_in_rect(Rect2(e.pos - e.half, e.half * 2.0)):
		if o == e or e.launch_hit_set.has(o):
			continue
		e.launch_hit_set.append(o)
		var h: Dictionary = {"damage": Tuning.t.heavy_damage * 0.4 * Run.power(), "kind": &"collide", "dir": e.vel.normalized(),
			"launch": false, "launch_speed": 0.0, "hitstun": 26, "pin": 0, "crush": 1.0, "src": e.pos}
		if o.take_hit(h):
			o.vel = e.vel * 0.5
			on_hit_landed(s, o, h)
	break_props(s, e)

static func beam_damage(s: Sim, origin: Vector2, dir: Vector2, length: float, width: float, dmg: float, skip: Object) -> EnemyBase:
	var first: EnemyBase = null
	var first_t: float = INF
	for e: EnemyBase in s.enemies:
		if not e.alive or e == skip:
			continue
		var rel: Vector2 = s.grid.delta(origin, e.pos)
		var t: float = rel.dot(dir)
		if t < 0.0 or t > length:
			continue
		var perp: float = absf(rel.cross(dir))
		if perp <= width * 0.5 + e.half.length() * 0.7:
			e.flash_t = 3
			e.take_raw_damage(dmg)
			if e.alive and e.state != EnemyBase.S.LAUNCHED:
				e.state = EnemyBase.S.HITSTUN
				e.state_t = maxi(e.state_t, 6)
				e.vel = dir * 3.0 * U
			if Run.tick % 6 == 0:
				Multiverse.add_exposure(Tuning.prog.exposure_per_hit)
			if t < first_t:
				first_t = t
				first = e
	return first
