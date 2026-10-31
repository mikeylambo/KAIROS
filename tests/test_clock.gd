extends GutTest
## Life clock invariants (GDD §5) and the power curve.

var clock: RunClock

func before_each() -> void:
	clock = RunClock.new()
	clock.setup(Tuning.t, 1800.0)

func test_thresholds_fire_once_in_order() -> void:
	var seen: Array = []
	clock.threshold_reached.connect(func(i: int) -> void: seen.append([i, clock.elapsed()]))
	for k: int in 1800 * 4:
		clock.tick(0.25)
	assert_eq(seen.size(), 3)
	assert_eq(seen.map(func(x: Array) -> int: return x[0]), [0, 1, 2], "in order, once each")
	assert_almost_eq(float(seen[0][1]), 600.0, 0.3)
	assert_almost_eq(float(seen[1][1]), 1200.0, 0.3)
	assert_almost_eq(float(seen[2][1]), 1680.0, 0.3)

func test_overflow_only_after_28_scaled() -> void:
	var c2 := RunClock.new()
	c2.setup(Tuning.t, 120.0)
	var at: Array = []
	c2.overflow_started.connect(func() -> void: at.append(c2.elapsed()))
	while c2.phase == RunClock.Phase.LIVING:
		assert_false(c2.overflow and c2.elapsed() < 112.0 - 0.02, "no overflow before 28:00-equivalent")
		c2.tick(1.0 / 60.0)
	assert_eq(at.size(), 1)
	assert_almost_eq(float(at[0]), 112.0, 0.05, "28/30 of a 2:00 clock")

func test_clock_never_increases() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var last: float = clock.remaining
	for i: int in 5000:
		if rng.randf() < 0.1:
			clock.cost(rng.randf_range(-3.0, 8.0))
		else:
			clock.tick(rng.randf_range(-0.1, 0.3))
		assert_true(clock.remaining <= last, "remaining is monotonic")
		last = clock.remaining

func test_zero_enters_fade_fight_then_fades() -> void:
	var fades: Array = []
	clock.faded.connect(func() -> void: fades.append(1))
	clock.tick(1800.0)
	assert_eq(clock.phase, RunClock.Phase.FADE_FIGHT)
	clock.tick(30.0)
	assert_eq(clock.phase, RunClock.Phase.FADE_FIGHT)
	clock.tick(31.0)
	assert_eq(clock.phase, RunClock.Phase.FADED)
	assert_eq(fades.size(), 1)

func test_early_threat_kill_skips_fight() -> void:
	clock.tick(500.0)
	clock.end_threat()
	assert_eq(clock.phase, RunClock.Phase.FREE)
	clock.tick(1400.0)
	assert_eq(clock.phase, RunClock.Phase.FADED, "fades with no fight")

func test_power_floor_curve() -> void:
	var p: ProgressionDef = Tuning.prog
	assert_almost_eq(PowerCurve.floor_at(p, 0.0), 1.0, 0.0001)
	assert_almost_eq(PowerCurve.floor_at(p, 1.0), 3.5, 0.0001)
	assert_almost_eq(PowerCurve.floor_at(p, 0.5), 1.0 + 2.5 * pow(0.5, 1.4), 0.0001)

func test_band_factors() -> void:
	var p: ProgressionDef = Tuning.prog
	assert_eq(PowerCurve.band_factor(p, 1, 3), 0.1, "far below")
	assert_eq(PowerCurve.band_factor(p, 2, 2), 1.0, "equal")
	assert_eq(PowerCurve.band_factor(p, 3, 2), 3.0, "one above")
	assert_eq(PowerCurve.player_band(p, 0.0), 1)
	assert_eq(PowerCurve.player_band(p, 500.0), 2)
