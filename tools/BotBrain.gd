class_name BotBrain
extends RefCounted
## Scripted player. Reads only sim state → produces one packed input per tick.
## Modes: "fight" (string → launch → chase → string, beam crowds, perfect guard),
## "idle" (does nothing — lets the fade win), "travel" (hold right in the Corridor).

const U: float = 32.0

var mode: String = "fight"
var f: int = 0
var combo_step: int = 0
var combo_wait: int = 0
var ki_hold: int = 0
var last: int = 0
var guard_hold: int = 0
var allow_transmit: bool = true

func next_input(s: Sim) -> int:
	f += 1
	var held: int = 0
	var mv: Vector2 = Vector2.ZERO
	var z: Zenith = s.zenith
	if mode == "idle":
		return _emit(0, Vector2.ZERO)
	if s.is_corridor():
		return _emit(0, Vector2(1, 0))
	if s.bloom != null and s.bloom.phase == 3:
		return _emit(InputLog.B_KI if f % 2 == 0 else 0, Vector2.ZERO)
	var target: EnemyBase = _target(s)
	if target == null:
		mv = Vector2(1, -0.2)
		return _emit(InputLog.B_JUMP if (f % 30 == 0 and not z.flying) else 0, mv)
	var d: Vector2 = s.grid.delta(z.pos, target.pos)
	mv = d.normalized()
	# Defensive: perfect guard an incoming committed attack.
	var threat: EnemyBase = _threat(s)
	if threat and guard_hold == 0 and z.state == Zenith.S.NEUTRAL and (f % 3 != 0):
		guard_hold = 10
	if guard_hold > 0:
		guard_hold -= 1
		return _emit(InputLog.B_GUARD, Vector2.ZERO)
	# Beam crowds when ki allows.
	if ki_hold > 0 or (z.ki >= 45.0 and s.enemies_in_radius(z.pos, 22.0 * U).size() >= 3 and z.state == Zenith.S.NEUTRAL):
		ki_hold += 1
		if ki_hold < 40:
			return _emit(InputLog.B_KI, mv)
		ki_hold = 0
		return _emit(0, mv)
	if z.state == Zenith.S.BEAM_FIRE:
		return _emit(0, mv)
	var c: ZenithCombat = z.combat
	if c.chase_target != null and c.chase_t > 0 and c.chase_t < Tuning.t.chase_window_f - 6 and allow_transmit:
		combo_step = 0
		combo_wait = 3
		return _emit(InputLog.B_TRANSMIT, Vector2.ZERO)
	var close: bool = absf(d.x) < 3.4 * U and absf(d.y) < 2.2 * U
	if not close:
		combo_step = 0
		if d.length() > 14.0 * U and allow_transmit and f % 20 == 0:
			return _emit(InputLog.B_TRANSMIT, mv)
		if d.y < -1.5 * U and not z.flying and f % 12 == 0:
			held |= InputLog.B_JUMP
		if z.flying or d.y < -1.0 * U:
			return _emit(held | (InputLog.B_JUMP if not z.flying and f % 2 == 0 else 0), mv)
		return _emit(held, Vector2(signf(d.x), 0.0 if not z.flying else signf(d.y) * 0.6))
	if combo_wait > 0:
		combo_wait -= 1
		return _emit(0, Vector2(signf(d.x) * 0.3, 0))
	var face: Vector2 = Vector2(signf(d.x), 0)
	match combo_step:
		0, 1:
			combo_step += 1
			combo_wait = 8
			return _emit(InputLog.B_LIGHT, face * 0.3)
		2:
			combo_step += 1
			combo_wait = 12
			var dir: Vector2 = Vector2(signf(d.x), -1.0) if target.def.armor == 0 else face
			return _emit(InputLog.B_HEAVY, dir)
		_:
			combo_step = 0
			combo_wait = 6
			return _emit(InputLog.B_LIGHT, face * 0.3)

func _emit(held: int, mv: Vector2) -> int:
	# Release-then-press so every intended press is an edge.
	var press: int = held & ~last
	var keep: int = held & last & (InputLog.B_GUARD | InputLog.B_KI | InputLog.B_JUMP)
	var out: int = press | keep
	last = out
	return InputLog.pack(out, mv)

func _target(s: Sim) -> EnemyBase:
	var best: EnemyBase = null
	var bd: float = INF
	for e: EnemyBase in s.enemies:
		if not e.alive:
			continue
		var dd: float = s.grid.delta(s.zenith.pos, e.pos).length()
		if e.boss_part:
			dd *= 0.6
		if dd < bd:
			bd = dd
			best = e
	return best

func _threat(s: Sim) -> EnemyBase:
	for e: EnemyBase in s.enemies:
		if e.alive and e.state == EnemyBase.S.WINDUP and e.state_t <= 3 and s.grid.delta(s.zenith.pos, e.pos).length() < 9.0 * U:
			return e
	return null
