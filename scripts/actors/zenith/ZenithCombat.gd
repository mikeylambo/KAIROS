class_name ZenithCombat
extends RefCounted
## Frame-data driven combat (GDD Combat model + Feel Bible).

const U: float = 32.0

var z: Zenith
var move_id: String = ""
var frame: int = 0
var startup: int = 0
var active: int = 0
var recovery: int = 0
var light_idx: int = 0
var since_light: int = 999
var hit_set: Array = []
var launch_dir: Vector2 = Vector2.RIGHT
var chase_target: Object = null
var chase_t: int = 0
var guard_t: int = 0
var guard_blocked: bool = false
var guard_perfected: bool = false
var ki_hold: int = 0
var beam_charge: float = 0.0
var beam_frac: float = 0.0
var beam_t: int = 0
var beam_dir: Vector2 = Vector2.RIGHT
var beam_killed: bool = false

func cancel() -> void:
	move_id = ""
	frame = 0
	hit_set.clear()
	beam_t = 0

func _t() -> KairosTuning:
	return Tuning.t

func aim(inp: SimInput) -> Vector2:
	var d: Vector2 = SimInput.snap8(inp.move)
	return d if d != Vector2.ZERO else Vector2(z.facing, 0)

func step(inp: SimInput) -> void:
	since_light += 1
	if chase_t > 0:
		chase_t -= 1
		if chase_t == 0 or chase_target == null or not chase_target.is_launched():
			chase_target = null
			chase_t = 0
	if z.state == Zenith.S.STAGGER:
		return
	_ki_input(inp)
	match z.state:
		Zenith.S.NEUTRAL:
			_neutral(inp)
		Zenith.S.ATTACK, Zenith.S.VOLLEY, Zenith.S.FIELD:
			_run_move(inp)
		Zenith.S.TRANSMIT:
			z.state_t -= 1
			if not _try_attack(inp) and not _try_transmit() and z.state_t <= 0:
				z.state = Zenith.S.NEUTRAL
		Zenith.S.GUARD:
			_guard(inp)
		Zenith.S.RECOVER:
			z.state_t -= 1
			if z.state_t <= 0:
				z.state = Zenith.S.NEUTRAL
		Zenith.S.BEAM_CHARGE:
			ZenithKi.charge(self, inp)
		Zenith.S.BEAM_FIRE:
			ZenithKi.fire_tick(self, inp)

func _ki_input(inp: SimInput) -> void:
	if inp.is_held(InputLog.B_KI):
		ki_hold += 1
	if inp.is_pressed(InputLog.B_KI) and Run.build.flag(&"transmission_beam") and Run.tick - z.last_transmit_tick <= 20 \
			and z.ki >= _t().ki_beam and (z.state == Zenith.S.TRANSMIT or z.state == Zenith.S.NEUTRAL):
		beam_charge = 0.6
		ZenithKi.begin_fire(self, inp)
		ki_hold = -9999
		return
	if inp.is_released(InputLog.B_KI):
		if ki_hold > 0 and ki_hold < 12 and z.state == Zenith.S.NEUTRAL and z.ki >= _t().ki_volley:
			_start(Zenith.S.VOLLEY, "volley", _t().volley_startup, 1, _t().volley_recovery)
		ki_hold = 0
	if ki_hold >= 12 and z.state == Zenith.S.NEUTRAL and z.ki >= _t().ki_beam:
		z.state = Zenith.S.BEAM_CHARGE
		beam_charge = 0.0
		beam_dir = aim(inp)

func _neutral(inp: SimInput) -> void:
	if z.buffered(InputLog.B_BURST) and z.burst_cd == 0 and z.burst_t == 0:
		z.consume(InputLog.B_BURST)
		z.start_burst(SimInput.snap8(inp.move))
		return
	if inp.is_pressed(InputLog.B_GUARD) or (inp.is_held(InputLog.B_GUARD) and z.burst_t == 0):
		z.state = Zenith.S.GUARD
		guard_t = 0
		guard_blocked = false
		guard_perfected = false
		return
	if _try_attack(inp):
		return
	if _try_transmit():
		return
	if z.buffered(InputLog.B_FIELD) and z.ki >= _t().ki_field:
		z.consume(InputLog.B_FIELD)
		_start(Zenith.S.FIELD, "field", _t().field_startup, _t().field_active, _t().field_recovery)

func _try_attack(inp: SimInput) -> bool:
	var t: KairosTuning = _t()
	if z.buffered(InputLog.B_HEAVY):
		z.consume(InputLog.B_HEAVY)
		if z.burst_t > 0:
			Run.insights.note(&"heavy_while_bursting")
			if not Run.build.flag(&"burst_launcher"):
				z.burst_t = 0
		var now_dir: Vector2 = SimInput.snap8(inp.move)
		launch_dir = now_dir if now_dir != Vector2.ZERO else (z.heavy_press_dir if z.heavy_press_dir != Vector2.ZERO else Vector2(z.facing, 0))
		_start(Zenith.S.ATTACK, "heavy", t.heavy_startup, t.heavy_active, t.heavy_recovery)
		return true
	if z.buffered(InputLog.B_LIGHT):
		z.consume(InputLog.B_LIGHT)
		if since_light > t.light_reset_f or light_idx > 2:
			light_idx = 0
		var i: int = light_idx
		_start(Zenith.S.ATTACK, "light%d" % i, t.light_startup[i], t.light_active, t.light_recovery[i])
		light_idx = (i + 1) % 3
		since_light = 0
		return true
	return false

func _try_transmit() -> bool:
	if not z.buffered(InputLog.B_TRANSMIT) or Run.has_restraint(&"no_transmit"):
		return false
	z.consume(InputLog.B_TRANSMIT)
	return ZenithTransmit.attempt(self)

func _start(st: Zenith.S, id: String, su: int, ac: int, rc: int) -> void:
	z.state = st
	move_id = id
	frame = 1  # the press frame is startup frame 1
	startup = su
	active = ac
	recovery = rc
	hit_set.clear()

func _run_move(inp: SimInput) -> void:
	frame += 1
	if frame > startup and frame <= startup + active:
		if frame == startup + 1:
			_on_active_start(inp)
		if move_id.begins_with("light") or move_id == "heavy":
			ZenithMelee.sweep(self)
		elif move_id == "field":
			ZenithKi.field_tick(self)
	elif frame > startup + active:
		if move_id.begins_with("light") or move_id == "heavy":
			if z.buffered(InputLog.B_BURST) and z.burst_cd == 0:
				z.consume(InputLog.B_BURST)
				cancel()
				z.state = Zenith.S.NEUTRAL
				z.start_burst(SimInput.snap8(inp.move))
				return
			if z.buffered(InputLog.B_TRANSMIT) and _try_transmit():
				return
			if move_id.begins_with("light") and (z.buffered(InputLog.B_LIGHT) or z.buffered(InputLog.B_HEAVY)):
				_try_attack(inp)
				return
		if frame >= startup + active + recovery:
			if move_id.begins_with("light") or move_id == "heavy":
				if hit_set.is_empty():
					Events.whiff.emit(z.pos)
			cancel()
			z.state = Zenith.S.NEUTRAL

func _on_active_start(inp: SimInput) -> void:
	if move_id == "volley":
		ZenithKi.volley(self, inp)
	elif move_id == "field":
		z.add_ki(-_t().ki_field)
		var r: float = _t().field_radius * Run.build.mul(&"field_radius") * U
		Events.field_fired.emit(z.pos, r)
		Run.request_hitstop(4)

func _guard(inp: SimInput) -> void:
	guard_t += 1
	if not inp.is_held(InputLog.B_GUARD):
		if guard_perfected or guard_blocked:
			z.state = Zenith.S.NEUTRAL
		else:
			z.state = Zenith.S.RECOVER
			z.state_t = _t().guard_whiff_recovery_f
		return

func on_perfect_guard(src: Vector2) -> void:
	var origin: Vector2 = z.pos
	guard_perfected = true
	var away: Vector2 = z.sim.grid.delta(z.pos, src)
	var dest: Vector2 = src + away.normalized() * _t().transmit_behind * U
	if not z.sim.grid.rect_blocked(dest, z.half):
		z.pos = z.sim.grid.wrap_pos(dest)
		z.facing = -1 if away.x > 0.0 else 1
	z.add_ki(_t().ki_per_perfect)
	z.iframes = _t().perfect_freeze_f + 6
	z.state = Zenith.S.NEUTRAL
	z.afterimage_ticks = 10
	Run.request_hitstop(_t().perfect_freeze_f)
	Events.perfect_guard.emit(origin)
	for sp: Array in Run.build.spawns_for(&"perfect_guard"):
		for i: int in int(sp[1]):
			z.sim.spawn_echo(origin + Vector2((i * 2 - 1) * 24.0, 0.0))
