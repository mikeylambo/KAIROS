extends GutTest
## Restraints, attack tokens, pause / focus loss / disconnect, settings persistence.

const U: float = 32.0
const RUN := preload("res://scenes/run/run.tscn")

func test_no_transmit_restraint() -> void:
	var sim: Sim = TestWorld.make(self, 1, 1800.0, true, {"restraints": ["no_transmit"]})
	var e: EnemyBase = TestWorld.dummy(sim, &"drone", Vector2(15.0 * U, 0))
	var p0: Vector2 = sim.zenith.pos
	TestWorld.tap(sim, InputLog.B_TRANSMIT)
	assert_eq(sim.zenith.pos, p0, "transmit disabled")
	assert_true(e.alive)
	sim.queue_free()

func test_half_time_restraint() -> void:
	var sim: Sim = TestWorld.make(self, 1, 1800.0, true, {"restraints": ["half_time"]})
	assert_eq(Run.clock.start, 900.0, "half a life")
	sim.queue_free()

func test_daily_seed_is_stable() -> void:
	assert_eq(RunSetup.daily_seed(), RunSetup.daily_seed())
	assert_gt(RunSetup.daily_seed(), 20000000)

func test_attack_tokens_cap_two() -> void:
	var sim: Sim = TestWorld.make(self)
	sim.zenith.iframes = 0
	Dev.god_mode = true
	for i: int in 6:
		var e: EnemyBase = sim.spawner._spawn_at(&"drone", sim.zenith.pos + Vector2((i - 3) * 2.0 * U, -2.0 * U))
		e.cooldown = 0
		e.state = EnemyBase.S.APPROACH
	var worst: int = 0
	for t: int in 900:
		TestWorld.step(sim, 1, 0)
		var n: int = 0
		for e: EnemyBase in sim.enemies:
			if e.alive and e.is_threatening():
				n += 1
		worst = maxi(worst, n)
	Dev.god_mode = false
	assert_eq(worst, 2, "never more than 2 enemies in windup/attack")
	sim.queue_free()

func _run_scene() -> RunScene:
	Profile.persist = false
	var rs: RunScene = RUN.instantiate()
	rs.config = {"seed": 3, "clock": 1800.0}
	add_child(rs)
	return rs

func test_focus_loss_pauses_and_stops_clock() -> void:
	var rs: RunScene = _run_scene()
	await get_tree().process_frame
	rs._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(rs.paused, "focus loss → pause")
	var r0: float = Run.clock.remaining
	for i: int in 30:
		rs._physics_process(0.0)
	assert_eq(Run.clock.remaining, r0, "clock stopped while paused")
	rs.queue_free()

func test_pad_disconnect_pauses() -> void:
	var rs: RunScene = _run_scene()
	await get_tree().process_frame
	rs._on_joy(0, false)
	assert_true(rs.paused, "disconnect → pause")
	assert_true(rs.pause.visible, "reconnect prompt shown")
	rs.queue_free()

func test_abandon_records_run() -> void:
	var rs: RunScene = _run_scene()
	await get_tree().process_frame
	var n0: int = (Profile.data["history"] as Array).size()
	rs._abandon()
	assert_eq((Profile.data["history"] as Array).size(), n0 + 1)
	assert_eq(Profile.data["history"][0]["result"], "abandoned")
	rs.queue_free()

func test_settings_persist() -> void:
	var path: String = "user://test_settings.json"
	Profile.path_override = path
	Profile.persist = true
	Profile.data = Profile.fresh()
	Profile.set_setting("shake", 0.25)
	Profile.set_setting("numeric_clock", true)
	Profile.data = {}
	Profile.load_profile()
	assert_eq(float(Profile.setting("shake")), 0.25)
	assert_true(Profile.setting("numeric_clock"))
	Profile.path_override = ""
	Profile.persist = false
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test_settings.bak.json")
	Profile.load_profile()

func test_remap_persists() -> void:
	var path: String = "user://test_binds.json"
	Profile.path_override = path
	Profile.persist = true
	Profile.data = Profile.fresh()
	var k := InputEventKey.new()
	k.physical_keycode = KEY_N
	Settings.bind("light", k)
	Profile.data = {}
	Profile.load_profile()
	Settings.apply_bindings()
	var found: bool = false
	for ev: InputEvent in InputMap.action_get_events("light"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_N:
			found = true
	assert_true(found, "rebinding survives a reload")
	Profile.path_override = ""
	Profile.persist = false
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test_binds.bak.json")
	Profile.data = Profile.fresh()
	InputMap.load_from_project_settings()
