class_name EnemyBrain
extends RefCounted
## Idle → Approach → Windup (telegraph) → Attack → Recover. Commit, telegraph,
## get bodied. Behavior keyed by EnemyDef.behavior (data), never by dimension.

const U: float = 32.0

static func think(e: EnemyBase) -> void:
	var z: Zenith = e.sim.zenith
	var to_z: Vector2 = e.sim.grid.delta(e.pos, z.pos)
	var dist: float = to_z.length()
	match e.state:
		EnemyBase.S.IDLE:
			e.state_t -= 1
			_drift(e, to_z, 0.3)
			if e.state_t <= 0 or dist < 30.0 * U:
				e.state = EnemyBase.S.APPROACH
		EnemyBase.S.APPROACH:
			_approach(e, to_z, dist)
			if e.cooldown == 0 and dist <= e.def.attack_range * U and e.sim.tokens.acquire(e):
				e.state = EnemyBase.S.WINDUP
				e.state_t = e.def.windup_f
				e.aim = z.pos
				e.attack_dir = to_z.normalized() if dist > 1.0 else Vector2(e.facing, 0)
				Events.enemy_windup.emit(e.pos)
		EnemyBase.S.WINDUP:
			e.state_t -= 1
			e.vel = e.vel.move_toward(Vector2.ZERO, 40.0 * U / 60.0)
			if e.def.behavior != &"slammer":
				e.attack_dir = e.sim.grid.delta(e.pos, z.pos).normalized()
			e.facing = 1 if e.attack_dir.x >= 0.0 else -1
			if e.state_t <= 0:
				e.state = EnemyBase.S.ATTACK
				e.state_t = _attack_len(e)
				e.attack_hit_done = false
				_begin_attack(e)
		EnemyBase.S.ATTACK:
			e.state_t -= 1
			_attack_tick(e)
			if e.state_t <= 0:
				e.state = EnemyBase.S.RECOVER
				e.state_t = e.def.recover_f
				e.sim.tokens.release(e)
		EnemyBase.S.RECOVER:
			e.state_t -= 1
			e.vel = e.vel.move_toward(Vector2.ZERO, 30.0 * U / 60.0)
			if e.state_t <= 0:
				e.state = EnemyBase.S.APPROACH
				e.cooldown = 50 + (e.index * 17) % 60

static func _drift(e: EnemyBase, to_z: Vector2, k: float) -> void:
	if e.uses_gravity():
		e.vel.x = move_toward(e.vel.x, signf(to_z.x) * e.def.speed * U * k, 20.0 * U / 60.0)
	else:
		var bob: Vector2 = Vector2(0, sin(e.anim_t * 2.0 + e.index) * 2.0 * U)
		e.vel = e.vel.move_toward(bob, 20.0 * U / 60.0)

static func _approach(e: EnemyBase, to_z: Vector2, dist: float) -> void:
	var sp: float = e.def.speed * U
	var want: Vector2
	match e.def.behavior:
		&"gunner":
			var keep: float = 16.0 * U
			var dx: float = signf(to_z.x) * (1.0 if dist > keep else -1.0)
			want = Vector2(dx * sp, 0)
		&"flyer":
			var ang: float = float(e.index) * 1.256 + e.anim_t * 0.6
			var target: Vector2 = to_z + Vector2(cos(ang), sin(ang) * 0.6 - 0.5) * 6.0 * U
			want = target.normalized() * sp * minf(1.0, target.length() / (2.0 * U))
		&"lancer":
			var tgt: Vector2 = to_z + Vector2(-signf(to_z.x) * 18.0 * U, -2.0 * U)
			want = tgt.normalized() * sp * minf(1.0, tgt.length() / (2.0 * U))
		_:
			if e.uses_gravity():
				want = Vector2(signf(to_z.x) * sp if dist > 2.0 * U else 0.0, 0)
			else:
				var off: Vector2 = to_z - to_z.normalized() * 4.0 * U + Vector2(0, -1.0 * U)
				want = off.normalized() * sp * minf(1.0, off.length() / (2.0 * U))
	if e.uses_gravity():
		e.vel.x = move_toward(e.vel.x, want.x, 30.0 * U / 60.0)
	else:
		e.vel = e.vel.move_toward(want, 30.0 * U / 60.0)
	if absf(to_z.x) > 2.0:
		e.facing = 1 if to_z.x > 0.0 else -1

static func _attack_len(e: EnemyBase) -> int:
	match e.def.behavior:
		&"lancer":
			return 50
		&"slammer":
			return 40
		&"gunner":
			return 8
		&"brute":
			return 10
		&"flyer":
			return 20
	return e.def.attack_f

static func _begin_attack(e: EnemyBase) -> void:
	match e.def.behavior:
		&"slammer":
			e.vel = Vector2(e.attack_dir.x * 16.0 * U, -22.0 * U)
		&"gunner":
			e.sim.spawn_bolt(e.pos, e.attack_dir * 24.0 * U, false, 0.0)
			e.attack_hit_done = true
		&"lancer":
			e.attack_dir = Vector2(signf(e.attack_dir.x) if e.attack_dir.x != 0.0 else 1.0, 0)
		&"brute":
			Events.shake.emit(4.0)

static func _attack_tick(e: EnemyBase) -> void:
	var b: StringName = e.def.behavior
	match b:
		&"drone", &"spore":
			e.vel = e.attack_dir * 30.0 * U
		&"flyer":
			e.vel = e.attack_dir * 34.0 * U
		&"lancer":
			e.vel = e.attack_dir * 40.0 * U
		&"brute":
			e.vel.x = 0.0
		&"slammer":
			if e.sim.grid.on_floor(e.pos, e.half) and e.state_t < 34:
				if not e.attack_hit_done:
					Events.terrain_impact.emit(e.pos)
					e.sim.enemy_area_attack(e, 5.0 * U, true)
					e.attack_hit_done = true
				e.vel.x = 0.0
			return
		&"gunner":
			return
	if e.attack_hit_done:
		return
	var reach: Vector2 = e.half
	if b == &"brute":
		e.sim.enemy_area_attack(e, 4.5 * U, true)
		e.attack_hit_done = true
		return
	if e.sim.zenith_overlaps(e.pos, reach + Vector2(6, 6)):
		e.attack_hit_done = true
		e.sim.zenith.receive_attack(e.pos, e.def.heavy_attack, false, e.sim.band_damage_mul())
		if b == &"spore":
			e.sim.kill_enemy(e, false)
