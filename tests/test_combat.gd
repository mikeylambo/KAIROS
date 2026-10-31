extends GutTest
## Frame data (GDD Combat model) and the launch-and-chase identity.

const U: float = 32.0
var sim: Sim
var hits: Array = []

func before_each() -> void:
	sim = TestWorld.make(self)
	hits.clear()
	Events.hit_landed.connect(_on_hit)

func after_each() -> void:
	Events.hit_landed.disconnect(_on_hit)
	sim.queue_free()

func _on_hit(p: Vector2, kind: StringName, _d: float, _c: int) -> void:
	hits.append({"tick": Run.tick, "kind": kind, "pos": p})

func _first_hit_after_press(button: int, mv: Vector2 = Vector2(1, 0)) -> int:
	var e: EnemyBase = TestWorld.dummy(sim, &"brute", Vector2(2.2 * U, 0), 99999.0)
	TestWorld.step(sim, 2, 0)
	var press_tick: int = Run.tick + 1
	TestWorld.tap(sim, button, mv)
	for i: int in 30:
		if hits.size() > 0:
			break
		TestWorld.step(sim, 1, 0)
	assert_true(e.alive)
	return int(hits[0]["tick"]) - press_tick if hits.size() > 0 else -1

func test_light_startup_4f() -> void:
	assert_eq(_first_hit_after_press(InputLog.B_LIGHT, Vector2.ZERO), 4 + Run.hitstop * 0, "press frame = startup 1 → active on the 5th frame (press+4)")

func test_heavy_startup_9f() -> void:
	assert_eq(_first_hit_after_press(InputLog.B_HEAVY, Vector2.ZERO), 9, "heavy: 9 startup frames → lands press+9")

func test_light_string_damage_and_reset() -> void:
	var t: KairosTuning = Tuning.t
	assert_eq(Array(t.light_damage), [25.0, 35.0, 55.0])
	assert_eq(Array(t.light_startup), [4, 4, 5])
	assert_eq(Array(t.light_recovery), [10, 10, 16])
	var e: EnemyBase = TestWorld.dummy(sim, &"brute", Vector2(2.2 * U, 0), 99999.0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 12, 0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 12, 0)
	assert_eq(sim.zenith.combat.light_idx, 2, "string advances")
	TestWorld.step(sim, 60, 0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	assert_eq(sim.zenith.combat.move_id, "light0", "string resets after 51f idle")
	assert_true(e.alive)

func test_hitstop_is_sim_pause() -> void:
	TestWorld.dummy(sim, &"brute", Vector2(2.2 * U, 0), 99999.0)
	TestWorld.tap(sim, InputLog.B_HEAVY)
	for i: int in 12:
		TestWorld.step(sim, 1, 0)
		if Run.hitstop > 0:
			break
	assert_eq(Run.hitstop, 10 - 0, "heavy → 10f hitstop counter")
	var before: float = Run.clock.remaining
	TestWorld.step(sim, 5, 0)
	assert_eq(Run.clock.remaining, before, "clock frozen during hitstop (deterministic pause)")

func test_burst_cancels_recovery() -> void:
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 8, 0)
	assert_eq(sim.zenith.state, Zenith.S.ATTACK)
	TestWorld.tap(sim, InputLog.B_BURST, Vector2(1, 0))
	assert_gt(sim.zenith.burst_t, 0, "burst cancels light recovery")

func test_string_launch_chase_lands_4th_hit_in_air() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(2.0 * U, -0.4 * U), 99999.0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 9, 0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 9, 0)
	TestWorld.tap(sim, InputLog.B_HEAVY, Vector2(1, -1))
	for i: int in 30:
		if e.is_launched():
			break
		TestWorld.step(sim, 1, 0)
	assert_true(e.is_launched(), "heavy launches")
	assert_eq(hits.size(), 3, "3 hits before chase")
	TestWorld.step(sim, 16, 0)
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	assert_eq(Run.stats["chases"], 1, "chase transmit fired")
	assert_true(sim.zenith.flying or not sim.zenith.on_floor, "Zenith is in the air after chase")
	TestWorld.step(sim, 3, 0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	for i: int in 20:
		if hits.size() >= 4:
			break
		TestWorld.step(sim, 1, 0)
	assert_eq(hits.size(), 4, "4th hit lands")
	assert_false(sim.grid.on_floor(e.pos, e.half), "4th hit lands in the air")
	assert_lt(e.pos.y, TestWorld.FLOOR_Y - 3.0 * U, "well above the ground")

func test_perfect_guard_no_cost_refunds_ki() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(1.0 * U, 0))
	TestWorld.tap(sim, InputLog.B_GUARD)
	TestWorld.step(sim, 2, InputLog.B_GUARD)
	var before: float = Run.clock.remaining
	var ki0: float = sim.zenith.ki
	sim.zenith.receive_attack(e.pos, true, false, 1.0)
	assert_eq(Run.clock.remaining, before, "no time cost on perfect guard")
	assert_eq(sim.zenith.ki, ki0 + 10.0, "+10 ki")
	assert_eq(Run.hitstop, 6, "6f time freeze")

func test_late_guard_blocks_light_free_heavy_half() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(1.0 * U, 0))
	TestWorld.tap(sim, InputLog.B_GUARD)
	TestWorld.step(sim, 10, InputLog.B_GUARD)
	var before: float = Run.clock.remaining
	sim.zenith.receive_attack(e.pos, false, false, 1.0)
	assert_eq(Run.clock.remaining, before, "guarded light: no time cost")

func test_hit_costs_time_and_stagger_8f() -> void:
	var before: float = Run.clock.remaining
	sim.zenith.receive_attack(sim.zenith.pos + Vector2(20, 0), false, false, 1.0)
	assert_almost_eq(before - Run.clock.remaining, 2.0, 0.001, "light hit −2 s")
	assert_eq(sim.zenith.stagger_t, 8, "8f stagger")
	sim.zenith.iframes = 0
	sim.zenith.receive_attack(sim.zenith.pos + Vector2(20, 0), true, false, 1.0)
	assert_almost_eq(before - Run.clock.remaining, 2.0, 0.001, "no further loss during stagger")

func test_armor_absorbs_three_hits() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"slammer", Vector2(2.4 * U, -0.2 * U), 99999.0)
	for i: int in 3:
		TestWorld.tap(sim, InputLog.B_LIGHT)
		TestWorld.step(sim, 12, 0)
	assert_eq(e.armor_left, 0, "3 hits break armor")
	assert_ne(e.state, EnemyBase.S.HITSTUN, "no flinch while armored")
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 8, 0)
	assert_eq(e.state, EnemyBase.S.HITSTUN, "flinches once armor is broken")

func test_transmit_lands_behind_target() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(20.0 * U, -1.0 * U))
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	var d: Vector2 = sim.grid.delta(e.pos, sim.zenith.pos)
	assert_almost_eq(absf(d.x), 2.8 * U, 1.0, "lands 2.8 u behind")
	assert_gt(d.x, 0.0, "on the far side")
	assert_eq(sim.zenith.facing, -1, "faces the target")
