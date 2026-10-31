extends GutTest
## Determinism, replay, profile round-trip, insights, exposure → adaptation, mark.

const U: float = 32.0

func _bot_run(seed_v: int, ticks: int) -> Dictionary:
	var sim: Sim = TestWorld.make(self, seed_v, 120.0, false)
	sim.spawning_enabled = true
	var bot := BotBrain.new()
	for i: int in ticks:
		if Run.pending_threshold >= 0:
			Run.choose_option(Run.pending_options[0].id)
		if i == 900:
			Run.command("warp", "leadfall")
		sim.step_with_packed(bot.next_input(sim))
	var out: Dictionary = Run.summary()
	out["remaining"] = Run.clock.remaining
	out["pos"] = sim.zenith.pos
	out["log"] = Run.input_log
	sim.queue_free()
	return out

func test_same_seed_same_inputs_same_run() -> void:
	var a: Dictionary = _bot_run(42, 2400)
	var b: Dictionary = _bot_run(42, 2400)
	for k: String in ["peak_power", "kills", "longest_chain", "options", "remaining", "pos", "lost_to_hits"]:
		assert_eq(a[k], b[k], "identical " + k)

func test_replay_log_reproduces_run() -> void:
	var a: Dictionary = _bot_run(7, 2400)
	var log_a: InputLog = a["log"]
	var sim: Sim = TestWorld.make(self, 7, 120.0, false, {"replay": log_a})
	sim.spawning_enabled = true
	while Run.tick < log_a.frames.size() and Run.active:
		var before: int = Run.tick
		sim.step_with_packed(log_a.frames[Run.tick])
		if Run.tick == before:
			sim.step_with_packed(log_a.frames[mini(Run.tick, log_a.frames.size() - 1)])
	var s: Dictionary = Run.summary()
	assert_eq(s["kills"], a["kills"], "replay kills")
	assert_eq(s["peak_power"], a["peak_power"], "replay peak power")
	assert_eq(Run.clock.remaining, a["remaining"], "replay clock")
	assert_eq(sim.zenith.pos, a["pos"], "replay position")
	sim.queue_free()

func test_profile_round_trip() -> void:
	var path: String = "user://test_profile.json"
	Profile.path_override = path
	Profile.persist = true
	Profile.data = Profile.fresh()
	Profile.codex_add("insights", "burst_launcher")
	Profile.record_run({"peak_power": 4.2, "longest_chain": 31, "result": "success"})
	Profile.save()
	Profile.data = {}
	Profile.load_profile()
	assert_true(Profile.codex_has("insights", "burst_launcher"))
	assert_eq(float(Profile.data["best"]["peak_power"]), 4.2)
	assert_eq((Profile.data["history"] as Array).size(), 1)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{corrupt")
	f.close()
	Profile.load_profile()
	assert_eq(float(Profile.data["best"]["peak_power"]), 4.2, "corrupt → restored from backup")
	Profile.path_override = ""
	Profile.persist = false
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test_profile.bak.json")
	Profile.load_profile()

func test_codex_persists_across_two_runs() -> void:
	var path: String = "user://test_codex.json"
	Profile.path_override = path
	Profile.data = Profile.fresh()
	var sim: Sim = TestWorld.make(self)
	Profile.persist = true
	Run.insights.note(&"heavy_while_bursting")
	Run.insights.note(&"heavy_while_bursting")
	Run.insights.note(&"heavy_while_bursting")
	Run.clock.tick(5000.0)
	Run.clock.tick(5000.0)
	assert_false(Run.active, "run 1 ended")
	sim.queue_free()
	Profile.data = {}
	Profile.load_profile()
	sim = TestWorld.make(self)
	Profile.persist = true
	Run.grant_option(&"split_beam")
	Run.clock.tick(5000.0)
	Run.clock.tick(5000.0)
	sim.queue_free()
	Profile.data = {}
	Profile.load_profile()
	assert_true(Profile.codex_has("insights", "burst_launcher"), "insight from run 1 persists")
	assert_true(Profile.codex_has("options", "split_beam"), "technique from run 2 persists")
	assert_eq((Profile.data["history"] as Array).size(), 2, "two runs recorded")
	Profile.path_override = ""
	Profile.persist = false
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test_codex.bak.json")
	Profile.load_profile()

func test_insight_burst_launcher() -> void:
	var sim: Sim = TestWorld.make(self)
	assert_false(Run.build.flag(&"burst_launcher"))
	for i: int in 3:
		TestWorld.tap(sim, InputLog.B_BURST, Vector2(1, 0))
		TestWorld.step(sim, 2, 0)
		TestWorld.tap(sim, InputLog.B_HEAVY, Vector2(1, 0))
		TestWorld.step(sim, 50, 0)
	assert_true(Run.insights.found.has(&"burst_launcher"), "found after ×3")
	assert_true(Run.build.flag(&"burst_launcher"), "grants its variation")
	TestWorld.tap(sim, InputLog.B_BURST, Vector2(1, 0))
	TestWorld.step(sim, 2, 0)
	TestWorld.tap(sim, InputLog.B_HEAVY, Vector2(1, 0))
	assert_gt(sim.zenith.burst_t, 0, "variation: burst keeps going through the launcher")
	sim.queue_free()

func test_insight_transmission_beam() -> void:
	var sim: Sim = TestWorld.make(self)
	var e: EnemyBase = TestWorld.dummy(sim, &"brute", Vector2(15.0 * U, 0), 999999.0)
	for i: int in 3:
		sim.zenith.ki = 100.0
		TestWorld.tap(sim, InputLog.B_TRANSMIT)
		TestWorld.step(sim, 16, 0)
		TestWorld.step(sim, 1, 0)
		TestWorld.tap(sim, InputLog.B_KI)
		sim.zenith.combat.ki_hold = 12
		TestWorld.step(sim, 1, InputLog.B_KI)
		TestWorld.step(sim, 120, 0)
		e.pos = sim.zenith.pos + Vector2(15.0 * U, 0)
	assert_true(Run.insights.found.has(&"transmission_beam"), "found after ×3")
	sim.zenith.ki = 100.0
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	TestWorld.tap(sim, InputLog.B_KI)
	assert_eq(sim.zenith.state, Zenith.S.BEAM_FIRE, "variation: beam straight out of transmit")
	sim.queue_free()

func test_exposure_adapts_and_weight_marks_skyreach() -> void:
	var sim: Sim = TestWorld.make(self, 3, 1800.0, false)
	Run.command("warp", "leadfall")
	TestWorld.step(sim, 2, 0)
	assert_eq(Multiverse.current, &"leadfall")
	for i: int in 100:
		Multiverse.add_exposure(1.0)
	assert_true(Run.adaptations.has(&"weight"), "exposure 100 → Weight")
	var marks: Array = []
	Events.dimension_marked.connect(func(id: StringName) -> void: marks.append(id))
	Run.command("warp", "skyreach")
	TestWorld.step(sim, 2, 0)
	assert_eq(marks, [&"skyreach"], "Weight into Skyreach marks it")
	var f: EnemyBase = sim.spawner._spawn_at(&"flyer", sim.zenith.pos + Vector2(6 * U, -2 * U))
	f.grounded_fall = false
	TestWorld.step(sim, 1, 0)
	assert_true(f.grounded_fall, "flyers within 12 u fall")
	sim.queue_free()

func test_warp_costs_5s_corridor_is_free() -> void:
	var sim: Sim = TestWorld.make(self, 3, 1800.0, false)
	var r0: float = Run.clock.remaining
	Run.command("warp", "leadfall")
	assert_almost_eq(r0 - Run.clock.remaining, 5.0, 0.001, "warp −5 s")
	var r1: float = Run.clock.remaining
	Run.command("corridor", "skyreach")
	assert_eq(Run.clock.remaining, r1, "corridor costs nothing up front")
	TestWorld.step(sim, 2, 0)
	assert_eq(Multiverse.current, &"corridor")
	var n: int = 0
	while Multiverse.current == &"corridor" and n < 2000:
		TestWorld.step(sim, 1, 0, Vector2(1, 0))
		n += 1
	assert_eq(Multiverse.current, &"skyreach", "flying the corridor arrives")
	sim.queue_free()
