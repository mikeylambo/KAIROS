class_name EnemyBase
extends Node2D
## Enemy body: HP/armor, hit reactions, launch flight, pin, terrain. AI in EnemyBrain.

enum S { IDLE, APPROACH, WINDUP, ATTACK, RECOVER, HITSTUN, LAUNCHED, DEAD }

const U: float = 32.0

var sim: Node = null
var def: EnemyDef
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var half: Vector2 = Vector2(16, 16)
var hp: float = 60.0
var max_hp: float = 60.0
var armor_left: int = 0
var state: S = S.IDLE
var state_t: int = 0
var facing: int = -1
var alive: bool = false
var flies: bool = true
var grounded_fall: bool = false
var pin_t: int = 0
var flash_t: int = 0
var aim: Vector2 = Vector2.ZERO
var attack_dir: Vector2 = Vector2.RIGHT
var attack_hit_done: bool = false
var cooldown: int = 0
var index: int = 0
var band: int = 1
var boss_part: bool = false
var launch_dir: Vector2 = Vector2.ZERO
var launch_hit_set: Array = []
var anim_t: float = 0.0

func spawn(s: Node, d: EnemyDef, p: Vector2, hp_mul: float, i: int) -> void:
	sim = s
	def = d
	pos = p
	vel = Vector2.ZERO
	half = d.size * U * 0.5
	max_hp = d.hp * hp_mul
	hp = max_hp
	armor_left = d.armor
	flies = d.flies or Run.build.flag(&"enemies_fly")
	grounded_fall = false
	state = S.IDLE
	state_t = 20 + i * 7 % 40
	cooldown = 30 + (i * 13) % 50
	pin_t = 0
	flash_t = 0
	alive = true
	index = i
	visible = true
	position = p

func is_launched() -> bool:
	return alive and state == S.LAUNCHED

func is_threatening() -> bool:
	return state == S.WINDUP or state == S.ATTACK

func take_raw_damage(d: float) -> void:
	if not alive:
		return
	hp -= d
	flash_t = 6
	if hp <= 0.0:
		sim.kill_enemy(self)

func take_hit(h: Dictionary) -> bool:
	if not alive:
		return false
	var dmg: float = float(h["damage"])
	if pin_t > 0:
		dmg *= float(h.get("crush", 1.0))
	flash_t = 6
	sim.tokens.release(self)
	if armor_left > 0 and not h.get("break_armor", false):
		armor_left -= 1
		hp -= dmg * 0.5
		if hp <= 0.0:
			sim.kill_enemy(self)
		return true
	hp -= dmg
	if hp <= 0.0:
		sim.kill_enemy(self)
		return true
	var pin: int = int(h.get("pin", 0))
	if pin > 0:
		pin_t = pin
	if h.get("launch", false) and not boss_part:
		state = S.LAUNCHED
		launch_dir = h["dir"]
		vel = launch_dir * float(h["launch_speed"])
		state_t = Tuning.t.chase_window_f + int(Run.build.add(&"chase_window_f")) + 10
		launch_hit_set.clear()
		pin_t = 0
	else:
		state = S.HITSTUN
		state_t = int(h.get("hitstun", 18))
		var dir: Vector2 = h["dir"]
		vel = dir * 5.0 * U
		if not _grounded():
			vel.y = minf(vel.y, 0.0) * 0.3
	return true

func _grounded() -> bool:
	return sim.grid.on_floor(pos, half)

func uses_gravity() -> bool:
	return (not flies) or grounded_fall

func gravity() -> float:
	if grounded_fall:
		return 35.0 * U
	return Tuning.t.gravity * Run.build.mul(&"gravity") * U

func step() -> void:
	if not alive:
		return
	anim_t += 1.0 / 60.0
	flash_t = maxi(0, flash_t - 1)
	cooldown = maxi(0, cooldown - 1)
	if pin_t > 0:
		pin_t -= 1
		vel = Vector2.ZERO
		position = pos
		return
	match state:
		S.LAUNCHED:
			_launched()
		S.HITSTUN:
			state_t -= 1
			vel = vel.move_toward(Vector2.ZERO, 30.0 * U / 60.0)
			if uses_gravity() and not _grounded():
				vel.y += gravity() / 60.0 * 0.35
			_move()
			if state_t <= 0:
				state = S.APPROACH
				cooldown = maxi(cooldown, 30)
		_:
			EnemyBrain.think(self)
			if uses_gravity():
				vel.y = minf(vel.y + gravity() / 60.0, Tuning.t.terminal * U * (1.0 if not grounded_fall else 1.2))
			_move()
	position = pos

func _move() -> void:
	var r: Dictionary = sim.grid.move(pos, half, vel / 60.0, false)
	pos = r["pos"]
	if r["hit_floor"] and vel.y > 0.0:
		vel.y = 0.0
	if r["hit_x"]:
		vel.x = 0.0

func _launched() -> void:
	state_t -= 1
	vel *= 0.985
	var r: Dictionary = sim.grid.move(pos, half, vel / 60.0, false)
	pos = r["pos"]
	if r["hit_x"] or r["hit_floor"] or r["hit_ceil"]:
		if r["hit_x"]:
			vel.x = -vel.x * 0.45
		if r["hit_floor"] or r["hit_ceil"]:
			vel.y = -vel.y * 0.45
		Events.terrain_impact.emit(pos)
		sim.add_crater(pos)
		take_raw_damage(max_hp * 0.06)
	sim.launched_collisions(self)
	if alive and (state_t <= 0 or vel.length() < 4.0 * U):
		state = S.HITSTUN
		state_t = 20
