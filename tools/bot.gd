extends Node
## Bot playthroughs (BUILD_BRIEF §4 step 4). Full Main → Run → Legacy flow on a
## 2:00 clock: (a) win: adapt Weight, mark Skyreach, end the threat in the Fade
## Fight; (b) early hunt; (c) the fade wins. Run with --fixed-fps 60 headless.

const MAIN := preload("res://scenes/main.tscn")

func run() -> int:
	Profile.persist = false
	Engine.max_fps = 0
	var fails: int = 0
	fails += await _first60()
	fails += await _play("win", 1201)
	fails += await _play("early", 1202)
	fails += await _play("fade", 1203)
	print("bot: %s (%d failing)" % ["ALL PASS" if fails == 0 else "FAIL", fails])
	return 1 if fails > 0 else 0

func _first60() -> int:
	Profile.data = Profile.fresh()
	var main: Node = MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main._on_title_proceed("first")
	var rs: RunScene = main.current
	var dir := BotDirector.new("first60")
	rs.bot = dir
	var order: Array = []
	Events.tutorial_beat.connect(func(b: StringName) -> void: order.append(b))
	while Run.tick < 60 * 50:
		rs._physics_process(0.0)
		await get_tree().process_frame
	var fired: Dictionary = rs.director.fired
	var fails: int = 0
	var want_order: Array = [&"push_in", &"drones", &"heavy", &"first_chase", &"billboard", &"wave", &"map_pulse"]
	var in_order: bool = order == want_order
	print("bot first60: %s  order=%s" % ["PASS" if in_order else "FAIL", str(order)])
	if not in_order:
		fails += 1
	for b: StringName in want_order:
		var target: float = First60.BEATS[b]
		var at: float = float(fired.get(b, -99.0))
		var ok: bool = absf(at - target) <= 3.0
		if not ok:
			fails += 1
		print("bot   %s %-12s target %5.1fs  fired %5.1fs" % ["✔" if ok else "✘", b, target, at])
	main.queue_free()
	await get_tree().process_frame
	return fails

func _play(sc: String, seed_v: int) -> int:
	Profile.data = Profile.fresh()
	Profile.data["first_run_done"] = true
	var main: Node = MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var dir := BotDirector.new(sc)
	main.start_run({"seed": seed_v, "clock": 120.0})
	var rs: RunScene = main.current
	rs.bot = dir
	var frames: int = 0
	var t0: int = Time.get_ticks_msec()
	while main.state != main.St.LEGACY and frames < 60 * 60 * 6:
		# Extra sim steps per rendered frame keep the playthrough fast.
		if not rs.ended and is_instance_valid(rs):
			for k: int in 3:
				rs._physics_process(0.0)
		await get_tree().process_frame
		frames += 1
	var s: Dictionary = main.last_summary
	var checks: Array = []
	checks.append(["reached Legacy", main.state == main.St.LEGACY])
	checks.append(["clock never increased", not dir.clock_increased])
	checks.append(["thresholds once each in order", dir.thresholds.map(func(x: Array) -> int: return x[0]) == [0, 1, 2]])
	var marks_ok: bool = true
	for th: Array in dir.thresholds:
		var want: float = [40.0, 80.0, 112.0][int(th[0])]
		marks_ok = marks_ok and float(th[1]) < want and float(th[2]) >= want
	checks.append(["each threshold fires on the tick life crosses 10/20/28 (scaled)", marks_ok])
	match sc:
		"win":
			checks.append(["adapted Weight", (s.get("adaptations", []) as Array).has(&"weight")])
			checks.append(["marked Skyreach", (s.get("marked", []) as Array).has("skyreach")])
			checks.append(["threat ended in Fade Fight", s.get("threat_result", "") == "ended_fade_fight"])
			checks.append(["result success", s.get("result", "") == "success"])
		"early":
			checks.append(["threat ended early", s.get("threat_result", "") == "ended_early"])
			checks.append(["result success", s.get("result", "") == "success"])
		"fade":
			checks.append(["fade won", s.get("result", "") == "faded"])
			checks.append(["threat not ended", s.get("threat_result", "") == "unended"])
	var fails: int = 0
	for c: Array in checks:
		if not c[1]:
			fails += 1
	print("bot %s: %s  (%.1fs wall, ticks=%d, kills=%d, chain=%d, peak=%.2f, threat=%s @%.1f, opts=%s)" % [sc, "PASS" if fails == 0 else "FAIL",
		(Time.get_ticks_msec() - t0) / 1000.0, int(s.get("ticks", 0)), int(s.get("kills", 0)), int(s.get("longest_chain", 0)),
		float(s.get("peak_power", 0.0)), s.get("threat_result", "?"), float(s.get("threat_time", -1)), str(s.get("options", []))])
	for c: Array in checks:
		print("bot   %s %s" % ["✔" if c[1] else "✘", c[0]])
	if fails > 0:
		for l: String in dir.log_lines:
			print("bot   · ", l)
	main.queue_free()
	await get_tree().process_frame
	return fails
