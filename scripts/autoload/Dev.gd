extends Node
## Debug API shared by the F1 panel, the bot and screenshot capture.

var enabled: bool = OS.is_debug_build()
var god_mode: bool = false
var time_scale: float = 1.0
var _frame_times: PackedFloat32Array = PackedFloat32Array()
var _sampling: float = 0.0

func set_clock(seconds: float) -> void:
	var c: RunClock = Run.clock
	# Dev-only: moves the clock forward (never back) by draining.
	if seconds < c.remaining:
		c.tick(c.remaining - seconds)

func grant_adaptation(id: StringName) -> void:
	Run.grant_adaptation(id)

func warp(id: StringName) -> void:
	Run.command("warp", String(id))

func trigger_threshold(i: int) -> void:
	var c: RunClock = Run.clock
	if i < c.marks.size() and c.next_threshold <= i:
		set_clock(c.start - c.marks[i])

func spawn(enemy_id: StringName, n: int) -> void:
	if Run.sim:
		for i: int in n:
			Run.sim.spawn_enemy_near(enemy_id)

func trigger_fade() -> void:
	set_clock(0.0)

func perf_report(seconds: float) -> void:
	_frame_times = PackedFloat32Array()
	_sampling = seconds

func _process(delta: float) -> void:
	if _sampling > 0.0:
		_frame_times.append(delta * 1000.0)
		_sampling -= delta
		if _sampling <= 0.0:
			print(perf_string())

func perf_string() -> String:
	var arr: Array = Array(_frame_times)
	arr.sort()
	var n: int = arr.size()
	if n == 0:
		return "perf: no samples"
	var sum: float = 0.0
	for v: float in arr:
		sum += v
	var p99: float = arr[mini(n - 1, int(n * 0.99))]
	return "perf: frames=%d avg=%.2fms p99=%.2fms nodes=%d draw_calls=%d" % [n, sum / n, p99,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
