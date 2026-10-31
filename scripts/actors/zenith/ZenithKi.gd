class_name ZenithKi
extends RefCounted
## Ki volley, charge beam, burst field.

const U: float = 32.0

static func volley(c: ZenithCombat, inp: SimInput) -> void:
	var z: Zenith = c.z
	z.add_ki(-Tuning.t.ki_volley)
	var d: Vector2 = c.aim(inp)
	z.sim.spawn_bolt(z.pos + d * 24.0, d * Tuning.t.volley_speed * U, true, Tuning.t.volley_damage * Run.power())
	Events.volley_fired.emit(z.pos)

static func charge(c: ZenithCombat, inp: SimInput) -> void:
	var t: KairosTuning = Tuning.t
	var z: Zenith = c.z
	c.beam_charge = minf(1.0, c.beam_charge + Run.build.mul(&"beam_charge_rate") / float(t.beam_charge_max_f))
	var d: Vector2 = SimInput.snap8(inp.move)
	if d != Vector2.ZERO:
		c.beam_dir = d
	z.facing = 1 if c.beam_dir.x >= 0.0 else -1
	Events.beam_charge.emit(z.pos, c.beam_charge)
	if not inp.is_held(InputLog.B_KI):
		begin_fire(c, inp)

static func begin_fire(c: ZenithCombat, inp: SimInput) -> void:
	var t: KairosTuning = Tuning.t
	var z: Zenith = c.z
	if z.ki < t.ki_beam:
		z.state = Zenith.S.NEUTRAL
		return
	z.add_ki(-t.ki_beam)
	c.beam_frac = maxf(0.25, c.beam_charge)
	c.beam_t = int(20 + 40 * c.beam_frac)
	c.beam_killed = false
	var d: Vector2 = SimInput.snap8(inp.move)
	if d != Vector2.ZERO:
		c.beam_dir = d
	elif c.beam_dir == Vector2.ZERO:
		c.beam_dir = Vector2(z.facing, 0)
	z.state = Zenith.S.BEAM_FIRE
	z.state_t = c.beam_t
	if Run.tick - z.last_transmit_tick <= 20:
		Run.insights.note(&"beam_after_transmit")
	Events.beam_started.emit(z.pos)

static func beam_width(c: ZenithCombat) -> float:
	return (0.9 + 1.1 * c.beam_frac) * U * Run.build.mul(&"beam_width")

static func fire_tick(c: ZenithCombat, inp: SimInput) -> void:
	var t: KairosTuning = Tuning.t
	var z: Zenith = c.z
	var want: Vector2 = inp.move.normalized() if inp.move.length() > 0.2 else c.beam_dir
	var diff: float = wrapf(want.angle() - c.beam_dir.angle(), -PI, PI)
	var a: float = c.beam_dir.angle() + clampf(diff, -t.beam_steer / 60.0, t.beam_steer / 60.0)
	c.beam_dir = Vector2(cos(a), sin(a))
	var dmg: float = t.beam_dps / 60.0 * c.beam_frac * Run.power()
	var length: float = 40.0 * U
	var w: float = beam_width(c)
	var hit_any: Object = z.sim.beam_damage(z.pos, c.beam_dir, length, w, dmg)
	if hit_any != null and Run.build.flag(&"beam_split"):
		var ip: Vector2 = hit_any.pos
		for s: float in [-0.45, 0.45]:
			var dd: Vector2 = c.beam_dir.rotated(s)
			z.sim.beam_damage(ip, dd, 16.0 * U, w * 0.6, dmg * 0.6, hit_any)
		z.sim.split_points = [ip]
	else:
		z.sim.split_points = []
	z.state_t -= 1
	if z.state_t <= 0:
		z.state = Zenith.S.RECOVER
		z.state_t = t.beam_recovery_f
		z.sim.split_points = []
		Events.beam_ended.emit(z.pos, c.beam_killed)
		if c.beam_killed:
			Run.request_hitstop(t.beam_hitstop_f)

static func field_tick(c: ZenithCombat) -> void:
	var z: Zenith = c.z
	var r: float = Tuning.t.field_radius * Run.build.mul(&"field_radius") * U
	for e: Object in z.sim.enemies_in_radius(z.pos, r):
		if c.hit_set.has(e):
			continue
		c.hit_set.append(e)
		var dir: Vector2 = z.sim.grid.delta(z.pos, e.pos).normalized()
		var h: Dictionary = {"damage": Tuning.t.field_damage * Run.power(), "kind": &"field", "dir": dir,
			"launch": false, "launch_speed": 0.0, "hitstun": 24, "pin": 0, "crush": 1.0, "src": z.pos, "break_armor": true}
		if e.take_hit(h):
			z.sim.on_hit_landed(e, h)
	if Run.build.flag(&"field_reflect"):
		z.sim.reflect_bolts(z.pos, r)
	else:
		z.sim.clear_bolts(z.pos, r)
