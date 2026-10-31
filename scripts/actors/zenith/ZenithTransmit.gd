class_name ZenithTransmit
extends RefCounted
## Combat transmission: teleport behind nearest target, or — inside the chase
## window — into the launched enemy's flight path so it arrives into Zenith.

const U: float = 32.0

static func attempt(c: ZenithCombat) -> bool:
	var z: Zenith = c.z
	var t: KairosTuning = Tuning.t
	var g: TerrainGrid = z.sim.grid
	var origin: Vector2 = z.pos
	var dest: Vector2
	var chase: bool = false
	var face_to: Vector2
	if c.chase_target != null and c.chase_t > 0 and c.chase_target.is_launched():
		var e: Object = c.chase_target
		var lv: Vector2 = e.vel
		var ahead: Vector2 = e.pos + lv / 60.0 * 9.0
		dest = ahead + lv.normalized() * (t.transmit_behind * U)
		face_to = e.pos
		chase = true
	else:
		var target: Object = z.sim.nearest_target(z.pos, t.transmit_range * U)
		if target == null:
			return false
		var d: Vector2 = g.delta(z.pos, target.pos)
		var side: float = signf(d.x) if absf(d.x) > 1.0 else float(z.facing)
		dest = target.pos + Vector2(side * t.transmit_behind * U, -4.0)
		face_to = target.pos
	dest = _resolve(g, dest, z.half)
	z.pos = g.wrap_pos(dest)
	z.vel = Vector2.ZERO
	var fd: Vector2 = g.delta(z.pos, face_to)
	z.facing = 1 if fd.x >= 0.0 else -1
	if not g.on_floor(z.pos, z.half):
		z.flying = true
	z.burst_t = 0
	z.iframes = t.arrival_iframes_f
	z.afterimage_ticks = 8
	z.state = Zenith.S.TRANSMIT
	z.state_t = int(round(t.transmit_recovery_f * Run.build.mul(&"transmit_recovery")))
	c.cancel()
	z.last_transmit_tick = Run.tick
	Events.transmitted.emit(origin, z.pos, chase)
	if chase:
		Run.stats["chases"] = int(Run.stats["chases"]) + 1
		if int(Run.stats["first_chase_tick"]) < 0:
			Run.stats["first_chase_tick"] = Run.tick
		var dmg: float = Run.build.add(&"chase_arrival_dmg")
		if dmg > 0.0:
			c.chase_target.take_raw_damage(dmg * Run.power())
		z.sim.on_chase(c.chase_target)
	if z.state_t <= 0:
		z.state = Zenith.S.NEUTRAL
	return true

static func _resolve(g: TerrainGrid, p: Vector2, half: Vector2) -> Vector2:
	if not g.rect_blocked(p, half):
		return p
	for k: int in range(1, 8):
		var up: Vector2 = p + Vector2(0, -k * 16.0)
		if not g.rect_blocked(up, half):
			return up
	return p + Vector2(0, -160.0)
