extends GutTest
## GDD §7 movement numbers.

const U: float = 32.0
var sim: Sim

func before_each() -> void:
	sim = TestWorld.make(self)

func after_each() -> void:
	sim.queue_free()

func test_run_top_speed_and_accel() -> void:
	TestWorld.step(sim, 1, 0, Vector2(1, 0))
	var frames: int = 1
	while sim.zenith.vel.x < 18.0 * U - 0.01 and frames < 100:
		TestWorld.step(sim, 1, 0, Vector2(1, 0))
		frames += 1
	assert_almost_eq(sim.zenith.vel.x, 18.0 * U, 0.5, "run top speed 18 u/s")
	assert_between(frames, 17, 20, "reach top speed in ~18f (60 u/s²)")
	TestWorld.step(sim, 60, 0, Vector2(1, 0))
	assert_almost_eq(sim.zenith.vel.x, 18.0 * U, 0.5, "never exceeds top speed")

func test_reversal_decelerates_first() -> void:
	TestWorld.step(sim, 40, 0, Vector2(1, 0))
	TestWorld.step(sim, 1, 0, Vector2(-1, 0))
	assert_gt(sim.zenith.vel.x, 0.0, "no instant flip")
	assert_almost_eq(sim.zenith.vel.x, 18.0 * U - 50.0 * U / 60.0, 1.0, "decel 50 u/s² on reversal")

func test_jump_impulse_and_variable_height() -> void:
	TestWorld.tap(sim, InputLog.B_JUMP)
	assert_almost_eq(sim.zenith.vel.y, -24.0 * U + 48.0 * U / 60.0, 1.0, "jump impulse 24 u/s then gravity")
	TestWorld.step(sim, 3, InputLog.B_JUMP)
	var vy: float = sim.zenith.vel.y
	TestWorld.step(sim, 1, 0)
	assert_almost_eq(sim.zenith.vel.y, vy * 0.5 + 48.0 * U / 60.0, 2.0, "release → vy × 0.5")

func test_terminal_velocity() -> void:
	sim.zenith.pos.y -= 26.0 * U
	var vmax: float = 0.0
	for i: int in 70:
		TestWorld.step(sim, 1, 0)
		vmax = maxf(vmax, sim.zenith.vel.y)
	assert_almost_eq(vmax, 42.0 * U, 0.5, "terminal 42 u/s")

func test_gravity_doubles_in_leadfall_rule() -> void:
	Run.build.set_source("dimension", (load("res://data/dimensions/leadfall.tres") as DimensionDef).rules)
	sim.zenith.pos.y -= 20.0 * U
	TestWorld.step(sim, 1, 0)
	TestWorld.step(sim, 1, 0)
	var v1: float = sim.zenith.vel.y
	TestWorld.step(sim, 1, 0)
	assert_almost_eq(sim.zenith.vel.y - v1, 96.0 * U / 60.0, 0.5, "gravity ×2")

func test_coyote_window() -> void:
	sim.grid.fill(60, 30, 140, 4, TerrainGrid.EMPTY)
	sim.grid.fill(0, 33, 200, 1, TerrainGrid.SOLID)
	TestWorld.step(sim, 30, 0, Vector2(1, 0))
	assert_true(sim.zenith.on_floor, "still on the ledge")
	var left_floor: int = 0
	while sim.zenith.on_floor and left_floor < 200:
		TestWorld.step(sim, 1, 0, Vector2(1, 0))
		left_floor += 1
	TestWorld.step(sim, 5, 0, Vector2(1, 0))
	TestWorld.tap(sim, InputLog.B_JUMP, Vector2(1, 0))
	assert_lt(sim.zenith.vel.y, -20.0 * U, "jump allowed within 7f coyote")
	assert_false(sim.zenith.flying, "coyote jump, not flight")

func test_late_press_in_air_is_flight() -> void:
	sim.zenith.pos.y -= 10.0 * U
	TestWorld.step(sim, 12, 0)
	TestWorld.tap(sim, InputLog.B_JUMP)
	assert_true(sim.zenith.flying, "air press after coyote → flight")

func test_jump_buffer() -> void:
	sim.zenith.pos.y -= 3.0 * U
	var n: int = 0
	while sim.zenith.pos.y + sim.zenith.half.y < TestWorld.FLOOR_Y - 24.0 and n < 120:
		TestWorld.step(sim, 1, 0)
		n += 1
	assert_false(sim.zenith.on_floor, "pressed before landing")
	TestWorld.tap(sim, InputLog.B_JUMP)
	var jumped: bool = false
	for i: int in 8:
		TestWorld.step(sim, 1, 0)
		if sim.zenith.vel.y < -10.0 * U:
			jumped = true
			break
	assert_true(jumped, "buffered jump fires on landing")

func test_burst_duration_iframes_cooldown() -> void:
	TestWorld.tap(sim, InputLog.B_BURST, Vector2(1, 0))
	var frames: int = 0
	while sim.zenith.burst_t > 0:
		assert_true(sim.zenith.is_invulnerable(), "i-frames for full burst")
		assert_almost_eq(sim.zenith.vel.length(), 65.0 * U, 1.0, "burst 65 u/s")
		TestWorld.step(sim, 1, 0, Vector2(1, 0))
		frames += 1
	assert_eq(frames + 1, 11, "burst lasts 11f (press frame included)")
	assert_eq(sim.zenith.burst_cd, 21, "21f cooldown")
	TestWorld.tap(sim, InputLog.B_BURST, Vector2(1, 0))
	assert_eq(sim.zenith.burst_t, 0, "cooldown blocks re-burst")

func test_flight_top_speed_and_weight() -> void:
	sim.zenith.pos.y -= 10.0 * U
	sim.zenith.flying = true
	TestWorld.step(sim, 120, 0, Vector2(1, 0))
	assert_almost_eq(sim.zenith.vel.length(), 28.0 * U, 2.0, "flight 28 u/s")
	Run.grant_adaptation(&"weight")
	TestWorld.step(sim, 120, 0, Vector2(1, 0))
	assert_almost_eq(sim.zenith.vel.length(), 28.0 * U * 0.7, 2.0, "Weight → ×0.7")
