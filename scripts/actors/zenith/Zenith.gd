class_name Zenith
extends Node2D
## Gameplay state for Zenith. Owns kinematics, ki, combat state (GDD §15).
## Presentation lives in ZenithView, which only reads this node.

enum S { NEUTRAL, ATTACK, GUARD, STAGGER, TRANSMIT, BEAM_CHARGE, BEAM_FIRE, FIELD, VOLLEY, RECOVER }

const U: float = 32.0

var sim: Node = null
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var half: Vector2 = Vector2(13.0, 30.0)
var facing: int = 1
var on_floor: bool = false
var flying: bool = false
var coyote: int = 0
var jump_buf: int = 0
var jump_cut_done: bool = false
var held_jump_since_air: bool = false
var burst_t: int = 0
var burst_cd: int = 0
var burst_dir: Vector2 = Vector2.RIGHT
var iframes: int = 0
var stagger_t: int = 0
var state: S = S.NEUTRAL
var state_t: int = 0
var ki: float = 0.0
var combat: ZenithCombat = ZenithCombat.new()
## Frames left on each buffered action (bit → frames).
var buffer: Dictionary = {}
## Stick direction captured when Heavy was pressed (8-dir launch intent survives buffering).
var heavy_press_dir: Vector2 = Vector2.ZERO
var afterimage_ticks: int = 0
var last_transmit_tick: int = -999

func setup(s: Node, p: Vector2) -> void:
	sim = s
	pos = p
	vel = Vector2.ZERO
	combat = ZenithCombat.new()
	combat.z = self
	state = S.NEUTRAL
	position = p

func ki_max() -> float:
	return Tuning.t.ki_max + Run.build.add(&"ki_max")

func add_ki(v: float) -> void:
	ki = clampf(ki + v, 0.0, ki_max())

func can_turn() -> bool:
	return state == S.NEUTRAL or state == S.GUARD or state == S.BEAM_CHARGE

func is_invulnerable() -> bool:
	return iframes > 0 or burst_t > 0 or Dev.god_mode

func buffered(b: int) -> bool:
	return int(buffer.get(b, 0)) > 0

func consume(b: int) -> void:
	buffer[b] = 0

## During hitstop the sim is paused; presses are buffered, not dropped.
func step_buffer_only(inp: SimInput) -> void:
	for bit: int in [InputLog.B_LIGHT, InputLog.B_HEAVY, InputLog.B_TRANSMIT, InputLog.B_BURST, InputLog.B_FIELD]:
		if inp.is_pressed(bit):
			buffer[bit] = Tuning.t.input_buffer_f
			if bit == InputLog.B_HEAVY:
				heavy_press_dir = SimInput.snap8(inp.move)
	if inp.is_pressed(InputLog.B_JUMP):
		jump_buf = Tuning.t.jump_buffer_f
	if inp.is_held(InputLog.B_KI):
		combat.ki_hold += 1

func step(inp: SimInput) -> void:
	var t: KairosTuning = Tuning.t
	for bit: int in [InputLog.B_LIGHT, InputLog.B_HEAVY, InputLog.B_TRANSMIT, InputLog.B_BURST, InputLog.B_FIELD]:
		if inp.is_pressed(bit):
			buffer[bit] = t.input_buffer_f
			if bit == InputLog.B_HEAVY:
				heavy_press_dir = SimInput.snap8(inp.move)
		elif int(buffer.get(bit, 0)) > 0:
			buffer[bit] = int(buffer[bit]) - 1
	# Simultaneous Light+Heavy within 3f → Heavy.
	if buffered(InputLog.B_HEAVY) and buffered(InputLog.B_LIGHT) and int(buffer[InputLog.B_LIGHT]) >= t.input_buffer_f - 3:
		consume(InputLog.B_LIGHT)
	if inp.is_pressed(InputLog.B_JUMP):
		held_jump_since_air = true
	if inp.is_released(InputLog.B_JUMP):
		held_jump_since_air = false
	iframes = maxi(0, iframes - 1)
	burst_cd = maxi(0, burst_cd - 1)
	afterimage_ticks = maxi(0, afterimage_ticks - 1)
	if stagger_t > 0:
		stagger_t -= 1
		state = S.STAGGER
		if stagger_t == 0:
			state = S.NEUTRAL
	combat.step(inp)
	var can_move: bool = state == S.NEUTRAL or state == S.GUARD or state == S.BEAM_CHARGE \
		or (Run.build.flag(&"hover_combat") and flying and state != S.STAGGER)
	if state == S.ATTACK or state == S.VOLLEY or state == S.FIELD or state == S.BEAM_FIRE or state == S.TRANSMIT or state == S.RECOVER:
		if burst_t == 0:
			_attack_drift()
	ZenithMotor.step(self, inp, can_move)
	position = pos

func _attack_drift() -> void:
	var t: KairosTuning = Tuning.t
	if Run.build.flag(&"hover_combat") and flying:
		return
	if flying or state == S.TRANSMIT:
		vel = vel.move_toward(Vector2.ZERO, t.fly_decel * U * 3.0 / 60.0)
	if state == S.ATTACK and combat.move_id.begins_with("light"):
		var step_v: float = t.light_step * U * facing
		vel.x = move_toward(vel.x, step_v, t.run_decel * U / 60.0 * 2.0)
	elif on_floor:
		vel.x = move_toward(vel.x, 0.0, t.run_decel * U / 60.0)

func start_burst(dir: Vector2) -> void:
	var t: KairosTuning = Tuning.t
	burst_dir = dir if dir != Vector2.ZERO else Vector2(facing, 0)
	burst_t = t.burst_f
	afterimage_ticks = t.burst_f + 6
	Events.burst.emit(pos, burst_dir)

## Enemy attack contact. heavy/boss select the clock cost.
func receive_attack(src_pos: Vector2, heavy: bool, boss: bool, band_mul: float) -> void:
	if is_invulnerable():
		return
	var t: KairosTuning = Tuning.t
	if state == S.GUARD:
		if combat.guard_t <= t.guard_perfect_f:
			combat.on_perfect_guard(src_pos)
			return
		Events.guarded.emit(pos)
		combat.guard_blocked = true
		if heavy or boss:
			Run.clock.cost((t.cost_boss if boss else t.cost_heavy) * 0.5 * band_mul)
		return
	if stagger_t > 0:
		return
	var c: float = t.cost_boss if boss else (t.cost_heavy if heavy else t.cost_light)
	c *= band_mul
	Run.clock.cost(c)
	Run.stats["hits_taken"] = int(Run.stats["hits_taken"]) + 1
	stagger_t = t.stagger_f
	state = S.STAGGER
	combat.cancel()
	var kb: Vector2 = sim.grid.delta(src_pos, pos).normalized()
	vel = kb * 14.0 * U * Run.build.mul(&"knockback_taken")
	iframes = t.stagger_f + 12
	sim.break_chain()
	Events.zenith_hit.emit(pos, c)
	Events.shake.emit(5.0)
