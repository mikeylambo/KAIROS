extends GutTest
## Every threshold option must measurably change its target value (no stubs).

const U: float = 32.0
var sim: Sim

func before_each() -> void:
	sim = TestWorld.make(self)

func after_each() -> void:
	sim.queue_free()

func _charge_frames() -> int:
	sim.zenith.ki = 100.0
	var n: int = 0
	TestWorld.step(sim, 12, InputLog.B_KI)
	while sim.zenith.combat.beam_charge < 1.0 and n < 200:
		TestWorld.step(sim, 1, InputLog.B_KI)
		n += 1
	TestWorld.step(sim, 1, 0)
	return n

func test_resonant_beam() -> void:
	var base: int = _charge_frames()
	var w0: float = ZenithKi.beam_width(sim.zenith.combat)
	sim.queue_free()
	sim = TestWorld.make(self)
	Run.grant_option(&"resonant_beam")
	var fast: int = _charge_frames()
	assert_lt(float(fast), base / 1.35, "charge ≥40% faster")
	assert_almost_eq(ZenithKi.beam_width(sim.zenith.combat), w0 * 1.5, 0.01, "+50% width")

func test_omni_burst_field_radius_and_reflect() -> void:
	sim.zenith.ki = 100.0
	var far: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(13.0 * U, 0), 99999.0)
	TestWorld.tap(sim, InputLog.B_FIELD)
	TestWorld.step(sim, 20, 0)
	assert_eq(far.hp, 99999.0, "13 u is outside the base 10 u field")
	Run.grant_option(&"omni_burst_field")
	sim.zenith.ki = 100.0
	TestWorld.step(sim, 25, 0)
	TestWorld.tap(sim, InputLog.B_FIELD)
	TestWorld.step(sim, 20, 0)
	assert_lt(far.hp, 99999.0, "radius +60% reaches 13 u")

func test_reflect_turns_bolts() -> void:
	Run.grant_option(&"omni_burst_field")
	sim.spawn_bolt(sim.zenith.pos + Vector2(3 * U, 0), Vector2(-1 * U, 0), false, 0.0)
	sim.reflect_bolts(sim.zenith.pos, 16.0 * U)
	assert_true(sim.bolts[0]["friendly"], "enemy bolt now Zenith's")
	assert_gt((sim.bolts[0]["vel"] as Vector2).x, 0.0, "reversed")

func test_martial_fluency() -> void:
	var e: EnemyBase = TestWorld.dummy(sim, &"brute", Vector2(2.2 * U, 0), 99999.0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 8, 0)
	var k0: float = sim.zenith.ki
	sim.zenith.ki = 0.0
	Run.grant_option(&"martial_fluency")
	TestWorld.step(sim, 60, 0)
	TestWorld.tap(sim, InputLog.B_LIGHT)
	TestWorld.step(sim, 8, 0)
	assert_almost_eq(sim.zenith.ki, k0 * 1.5, 0.01, "+50% ki on hit")
	TestWorld.step(sim, 30, 0)
	e.pos = sim.zenith.pos + Vector2(20 * U, 0)
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	assert_eq(sim.zenith.state, Zenith.S.NEUTRAL, "transmit recovery 0f")

func test_phantom_echo() -> void:
	Run.grant_option(&"phantom_echo")
	TestWorld.tap(sim, InputLog.B_GUARD)
	sim.zenith.receive_attack(sim.zenith.pos + Vector2(30, 0), false, false, 1.0)
	assert_eq(sim.echoes.size(), 2, "2 detonating afterimages")

func test_vessel_expansion() -> void:
	assert_eq(sim.zenith.ki_max(), 100.0)
	Run.grant_option(&"vessel_expansion")
	sim.zenith.add_ki(500.0)
	assert_eq(sim.zenith.ki, 150.0, "max ki 150")

func test_split_beam_hits_off_axis() -> void:
	Run.grant_option(&"split_beam")
	TestWorld.dummy(sim, &"brute", Vector2(10.0 * U, 0), 99999.0)
	var side: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(18.0 * U, -4.0 * U), 99999.0)
	sim.zenith.ki = 100.0
	TestWorld.step(sim, 40, InputLog.B_KI, Vector2(1, 0))
	TestWorld.step(sim, 30, 0, Vector2(1, 0))
	assert_lt(side.hp, 99999.0, "split ray hits an enemy off the main axis")

func test_split_beam_absent_without_option() -> void:
	TestWorld.dummy(sim, &"brute", Vector2(10.0 * U, 0), 99999.0)
	var side: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(18.0 * U, -4.0 * U), 99999.0)
	sim.zenith.ki = 100.0
	TestWorld.step(sim, 40, InputLog.B_KI, Vector2(1, 0))
	TestWorld.step(sim, 30, 0, Vector2(1, 0))
	assert_eq(side.hp, 99999.0, "control: no split without the option")

func test_chase_mastery() -> void:
	Run.grant_option(&"chase_mastery")
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(2.0 * U, -0.4 * U), 99999.0)
	var at_launch: Array = []
	Events.launched.connect(func(_p: Vector2, _d: Vector2) -> void: at_launch.append(sim.zenith.combat.chase_t), CONNECT_ONE_SHOT)
	TestWorld.tap(sim, InputLog.B_HEAVY, Vector2(1, -1))
	TestWorld.step(sim, 12, 0)
	assert_eq(at_launch, [Tuning.t.chase_window_f + 40], "chase window +40f")
	var hp0: float = e.hp
	TestWorld.step(sim, 10, 0)
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	assert_almost_eq(hp0 - e.hp, 40.0 * Run.power(), 0.01, "arrival deals 40")
