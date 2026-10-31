class_name Platform
extends RefCounted
## All platform-specific code lives here (window, save path, achievements later).

static func save_dir() -> String:
	return "user://"

static func profile_path() -> String:
	return save_dir() + "profile.json"

static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"

static func set_fullscreen(on: bool) -> void:
	if is_headless():
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

static func quit(tree: SceneTree) -> void:
	tree.quit()
