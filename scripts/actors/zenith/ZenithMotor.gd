class_name ZenithMotor
extends RefCounted
## Movement per GDD §7. Operates on a Zenith; pixels internally, tuning in u.

const U: float = 32.0
const DT: float = 1.0 / 60.0

static func step(z: Zenith, inp: SimInput, can_move: bool) -> void:
	var t: KairosTuning = Tuning.t
	var b: BuildModifiers = Run.build
	var grid: TerrainGrid = z.sim.grid
	var no_ground: bool = b.flag(&"no_ground")
	var grav: float = t.gravity * b.mul(&"gravity") * U
	var stick: Vector2 = inp.move if inp.move.length() >= 0.2 else Vector2.ZERO
	z.on_floor = grid.on_floor(z.pos, z.half) and z.vel.y >= 0.0
	if no_ground or z.sim.is_corridor():
		z.flying = true
	if z.on_floor:
		# +1: decremented before the check below, so exactly coyote_f air frames remain.
		z.coyote = t.coyote_f + 1
		if z.flying and not no_ground and z.vel.y >= 0.0:
			z.flying = false
	else:
		z.coyote = maxi(0, z.coyote - 1)
	if inp.is_pressed(InputLog.B_JUMP):
		z.jump_buf = t.jump_buffer_f
	else:
		z.jump_buf = maxi(0, z.jump_buf - 1)
	if z.burst_t > 0:
		_burst(z, t)
	elif z.flying:
		_fly(z, t, b, stick if can_move else Vector2.ZERO, inp)
	else:
		_ground_air(z, t, grav, stick.x if can_move else 0.0, inp, can_move)
	var drop: bool = stick.y > 0.7 and not z.flying
	var r: Dictionary = grid.move(z.pos, z.half, z.vel * DT, drop)
	z.pos = r["pos"]
	if r["hit_floor"] and z.vel.y > 0.0:
		z.vel.y = 0.0
		z.on_floor = true
	if r["hit_ceil"] and z.vel.y < 0.0:
		z.vel.y = 0.0
	if r["hit_x"]:
		z.vel.x = 0.0
	if absf(z.vel.x) > 1.0 and z.burst_t == 0 and z.can_turn():
		z.facing = 1 if z.vel.x > 0.0 else -1
	if stick.x != 0.0 and can_move and z.can_turn():
		z.facing = 1 if stick.x > 0.0 else -1

static func _ground_air(z: Zenith, t: KairosTuning, grav: float, ix: float, inp: SimInput, can_move: bool) -> void:
	var target: float = ix * t.run_speed * U
	var accel: float = t.run_accel * U
	var decel: float = t.run_decel * U
	if not z.on_floor:
		accel *= t.air_control
		decel *= t.air_control
	var vx: float = z.vel.x
	if ix != 0.0 and vx != 0.0 and signf(ix) != signf(vx):
		vx = move_toward(vx, 0.0, decel * DT)
	elif ix != 0.0:
		vx = move_toward(vx, target, accel * DT)
	else:
		vx = move_toward(vx, 0.0, decel * DT)
	z.vel.x = vx
	if can_move and z.jump_buf > 0 and (z.on_floor or z.coyote > 0):
		z.vel.y = -t.jump_impulse * U
		z.jump_buf = 0
		z.coyote = 0
		z.on_floor = false
		z.jump_cut_done = false
		Events.jumped.emit(z.pos)
	elif can_move and inp.is_pressed(InputLog.B_JUMP) and not z.on_floor and z.coyote == 0 \
			and not _lands_within(z, grav, t.jump_buffer_f):
		z.flying = true
		z.vel.y = minf(z.vel.y, 0.0)
		return
	elif can_move and inp.is_held(InputLog.B_JUMP) and not z.on_floor and z.vel.y > 0.0 and z.jump_cut_done == false and z.held_jump_since_air:
		z.flying = true
		return
	if inp.is_released(InputLog.B_JUMP) and z.vel.y < 0.0 and not z.jump_cut_done:
		z.vel.y *= t.jump_cut
		z.jump_cut_done = true
	if not z.on_floor:
		z.vel.y = minf(z.vel.y + grav * DT, t.terminal * U)

## True if falling would reach ground within `frames` (then a press buffers a jump
## instead of starting flight — GDD jump buffer vs. second-press flight).
static func _lands_within(z: Zenith, grav: float, frames: int) -> bool:
	if z.vel.y < 0.0:
		return false
	var tt: float = float(frames) / 60.0
	var d: float = z.vel.y * tt + 0.5 * grav * tt * tt + 1.0
	var r: Dictionary = z.sim.grid.move(z.pos, z.half, Vector2(0, d), false)
	return r["hit_floor"]

static func _fly(z: Zenith, t: KairosTuning, b: BuildModifiers, stick: Vector2, inp: SimInput) -> void:
	var top: float = t.fly_speed * U * b.mul(&"fly_speed")
	var dir: Vector2 = stick.normalized() if stick != Vector2.ZERO else Vector2.ZERO
	if dir != Vector2.ZERO:
		var want: Vector2 = dir * top * minf(1.0, stick.length())
		var sp: float = z.vel.length()
		if sp > 1.0:
			var ang: float = z.vel.angle()
			var to: float = want.angle()
			var diff: float = wrapf(to - ang, -PI, PI)
			var maxturn: float = t.fly_turn * DT
			if absf(diff) > PI * 0.75:
				z.vel = z.vel.move_toward(Vector2.ZERO, t.fly_decel * U * DT * 2.0)
			else:
				ang += clampf(diff, -maxturn, maxturn)
				sp = move_toward(sp, want.length(), t.fly_accel * U * DT)
				z.vel = Vector2(cos(ang), sin(ang)) * sp
		else:
			z.vel = dir * t.fly_accel * U * DT
	else:
		z.vel = z.vel.move_toward(Vector2.ZERO, t.fly_decel * U * DT)
	if z.vel.length() > top and z.burst_t == 0:
		z.vel = z.vel.move_toward(z.vel.normalized() * top, t.fly_decel * U * DT * 2.0)
	if inp.is_pressed(InputLog.B_JUMP) and not b.flag(&"no_ground") and not z.sim.is_corridor():
		z.flying = false

static func _burst(z: Zenith, t: KairosTuning) -> void:
	z.vel = z.burst_dir * t.burst_speed * U
	z.burst_t -= 1
	if z.burst_t == 0:
		var top: float = (t.fly_speed if z.flying else t.run_speed) * U
		z.vel = z.burst_dir * top
		z.burst_cd = t.burst_cd_f
		if not z.flying and z.burst_dir.y < -0.1:
			z.flying = true
