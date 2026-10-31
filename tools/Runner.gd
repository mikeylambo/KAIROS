extends Node
## Runs a tool script (extends Node, has `func run() -> int`) after autoloads are
## live. Usage: godot --headless res://tools/runner.tscn -- --tool=res://tools/bot.gd [args]

func _ready() -> void:
	var path: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tool="):
			path = a.substr(7)
	if path == "":
		push_error("runner: missing --tool=")
		get_tree().quit(2)
		return
	var scr: GDScript = load(path)
	var n: Node = scr.new()
	add_child(n)
	var code: int = await n.run()
	get_tree().quit(code)
