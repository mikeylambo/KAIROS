extends Node
## Screenshot capture via the Dev API + bot. Needs a display:
## xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --fixed-fps 60 \
##   res://tools/runner.tscn -- --tool=res://tools/capture.gd [--size=1280x800] [--set=all|screens|clock]

const MAIN := preload("res://scenes/main.tscn")
const U: float = 32.0
var main: Node
var suffix: String = ""
var set_name: String = "all"
var pending: Array = []  # [frames_left, name]
var fast: int = 0

func run() -> int:
	Profile.persist = false
	Profile.data = Profile.fresh()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screens"))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--size="):
			var p: PackedStringArray = a.substr(7).split("x")
			get_window().size = Vector2i(int(p[0]), int(p[1]))
			get_window().content_scale_size = Vector2i(int(p[0]), int(p[1]))
			suffix = "_%sx%s" % [p[0], p[1]]
		if a.begins_with("--set="):
			set_name = a.substr(6)
	main = MAIN.instantiate()
	add_child(main)
	await _frames(20)
	await shot("title")
	if set_name in ["all", "screens"]:
		await _screens()
	if set_name in ["all", "first60"]:
		await _first60()
	if set_name in ["all", "clock"]:
		await _clock_read()
	if set_name in ["all", "run"]:
		await _full_run()
	return 0

func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://screens/%s%s.png" % [name, suffix]
	img.save_png(ProjectSettings.globalize_path(path))
	print("capture: ", path)

func _queue(name: String, delay: int) -> void:
	pending.append([delay, name])

func _pump(rs: RunScene, extra: int) -> void:
	for k: int in extra:
		if is_instance_valid(rs) and not rs.ended and pending.is_empty():
			rs._physics_process(0.0)
	await get_tree().process_frame
	var keep: Array = []
	for p: Array in pending:
		p[0] = int(p[0]) - 1
		if int(p[0]) <= 0:
			await shot(String(p[1]))
		else:
			keep.append(p)
	pending = keep

func _screens() -> void:
	for st: int in [main.St.SETUP, main.St.CODEX, main.St.SETTINGS]:
		main.goto(st)
		await _frames(10)
		await shot(["", "", "run_setup", "", "", "codex", "settings"][st])
	main.goto(main.St.TITLE)
	await _frames(5)

func _first60() -> void:
	main._on_title_proceed("first")
	var rs: RunScene = main.current
	rs.bot = BotDirector.new("first60")
	var beat_cb := func(b: StringName) -> void: _queue("first60_" + String(b), 25 if b != &"push_in" else 40)
	Events.tutorial_beat.connect(beat_cb)
	var launch_cb := func(_p: Vector2, _d: Vector2) -> void: _queue("feel_gate_launch", 1)
	Events.launched.connect(launch_cb, CONNECT_ONE_SHOT)
	var arrival := [false]
	var tx_cb := func(_a: Vector2, _b: Vector2, chase: bool) -> void:
		if chase and not arrival[0]:
			arrival[0] = true
			_queue("feel_gate_arrival", 2)
	Events.transmitted.connect(tx_cb)
	var beam_cb := func(_p: Vector2) -> void: _queue("feel_gate_beam", 14)
	Events.beam_started.connect(beam_cb, CONNECT_ONE_SHOT)
	var mid_done: bool = false
	while Run.tick < 60 * 52:
		var c: ZenithCombat = rs.sim.zenith.combat
		if not mid_done and c.chase_target != null and c.chase_t > 0 and c.chase_t < Tuning.t.chase_window_f - 8:
			mid_done = true
			await shot("feel_gate_midchase")
		await _pump(rs, 1)
	Events.tutorial_beat.disconnect(beat_cb)
	Events.transmitted.disconnect(tx_cb)
	await _frames(30)
	main.goto(main.St.TITLE)
	await _frames(5)

func _clock_read() -> void:
	main.start_run({"seed": 5, "clock": 1800.0})
	var rs: RunScene = main.current
	var brain := BotBrain.new()
	brain.mode = "idle"
	rs.bot = brain
	for e: EnemyBase in rs.sim.enemies:
		e.alive = false
	rs.sim.spawning_enabled = false
	Run.grant_option(&"vessel_expansion")
	var crops: Array[Image] = []
	for secs: float in [1800.0, 1200.0, 600.0, 90.0]:
		Dev.set_clock(secs)
		Run.pending_threshold = -1
		rs.threshold.visible = false
		rs.cam.threshold_zoom = false
		await _frames(90)
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var zp: Vector2 = rs.hud.world_to_screen(rs.sim.zenith.pos)
		var r := Rect2i(clampi(int(zp.x) - 260, 0, img.get_width() - 520), clampi(int(zp.y) - 230, 0, img.get_height() - 400), 520, 400)
		crops.append(img.get_region(r))
	var comp: Image = Image.create(520 * 4, 400, false, crops[0].get_format())
	for i: int in 4:
		comp.blit_rect(crops[i], Rect2i(0, 0, 520, 400), Vector2i(520 * i, 0))
	comp.save_png(ProjectSettings.globalize_path("res://screens/clock_read%s.png" % suffix))
	print("capture: clock_read (30:00 / 20:00 / 10:00 / 1:30)")
	main.goto(main.St.TITLE)
	await _frames(5)

func _full_run() -> void:
	Profile.data["first_run_done"] = true
	main.start_run({"seed": 1201, "clock": 120.0})
	var rs: RunScene = main.current
	var dir := BotDirector.new("win")
	rs.bot = dir
	var got: Dictionary = {}
	var cbs: Array = []
	cbs.append([Events.dimension_entered, func(id: StringName) -> void: _queue("dim_" + String(id), 70)])
	cbs.append([Events.dimension_marked, func(_id: StringName) -> void: _queue("weight_skyreach_mark", 20)])
	cbs.append([Events.adaptation_gained, func(_id: StringName) -> void: _queue("adaptation", 15)])
	cbs.append([Events.overflow_started, func() -> void: _queue("overflow", 90)])
	cbs.append([Events.fade_fight_started, func() -> void: _queue("fade_fight", 100)])
	cbs.append([Events.faded, func(_l: String) -> void:
		_queue("fade_dissolve", 100)
		_queue("fade_line", 330)])
	for c: Array in cbs:
		(c[0] as Signal).connect(c[1])
	var frames: int = 0
	while main.state != main.St.LEGACY and frames < 20000:
		frames += 1
		if Run.pending_threshold >= 0 and not got.has("threshold_choice"):
			got["threshold_choice"] = true
			await _frames(30)
			await shot("threshold_choice")
		if Multiverse.current == &"leadfall" and Run.clock.elapsed() > 30.0 and not got.has("map"):
			got["map"] = true
			Run.command("map", true)
			rs.map.open()
			await _frames(20)
			await shot("map")
			rs.map.close()
			rs.open_pause()
			await _frames(10)
			await shot("pause")
			rs.pause.visible = false
			rs.paused = false
		if rs.sim.bloom and rs.sim.bloom.phase == 3 and not got.has("clash"):
			got["clash"] = true
			_queue("beam_clash", 40)
		if rs.sim.bloom and rs.sim.bloom.phase == 2 and not got.has("bloom2"):
			got["bloom2"] = true
			_queue("bloom_phase2", 60)
		if rs.sim.bloom and rs.sim.bloom.phase == 1 and not got.has("bloom1"):
			got["bloom1"] = true
			_queue("bloom_phase1", 120)
		await _pump(rs, 2 if Run.clock.phase == RunClock.Phase.LIVING else 0)
	await _frames(40)
	await shot("legacy")
	for c: Array in cbs:
		(c[0] as Signal).disconnect(c[1])
