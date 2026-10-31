extends Node
## Screenshot capture via the Dev API. Needs a display (xvfb-run in CI):
## xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 \
##   res://tools/runner.tscn -- --tool=res://tools/capture.gd [--shots=a,b] [--size=1280x800]

const MAIN := preload("res://scenes/main.tscn")
var main: Node
var only: PackedStringArray = PackedStringArray()

func run() -> int:
	Profile.persist = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screens"))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			only = a.substr(8).split(",")
		if a.begins_with("--size="):
			var p: PackedStringArray = a.substr(7).split("x")
			get_window().size = Vector2i(int(p[0]), int(p[1]))
	main = MAIN.instantiate()
	add_child(main)
	await _frames(30)
	await shot("title")
	main.start_run({"seed": 11, "clock": 1800.0})
	var rs: RunScene = main.current
	var bot := BotBrain.new()
	rs.bot = bot
	await _frames(240)
	await shot("run_threshold")
	return 0

func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame

func shot(name: String) -> void:
	if only.size() > 0 and not only.has(name):
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var sz: Vector2i = get_window().size
	var path: String = "res://screens/%s%s.png" % [name, "" if sz.x == 1920 else "_%dx%d" % [sz.x, sz.y]]
	img.save_png(ProjectSettings.globalize_path(path))
	print("capture: ", path)
