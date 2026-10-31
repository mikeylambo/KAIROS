class_name Settings
extends RefCounted
## Applies persisted settings to engine/audio/input. Called at boot and on change.

static func apply_all() -> void:
	Engine.time_scale = float(Profile.setting("game_speed"))
	Platform.set_fullscreen(bool(Profile.setting("fullscreen")))
	Audio.apply_volumes()
	apply_bindings()

static func apply_bindings() -> void:
	var binds: Dictionary = Profile.setting("bindings")
	for action: String in binds:
		if not InputMap.has_action(action):
			continue
		var entry: Dictionary = binds[action]
		var keep: Array[InputEvent] = []
		for ev: InputEvent in InputMap.action_get_events(action):
			var is_key: bool = ev is InputEventKey
			if (is_key and entry.has("key")) or (not is_key and entry.has("pad")):
				continue
			keep.append(ev)
		InputMap.action_erase_events(action)
		for ev: InputEvent in keep:
			InputMap.action_add_event(action, ev)
		if entry.has("key"):
			var k := InputEventKey.new()
			k.physical_keycode = int(entry["key"]) as Key
			InputMap.action_add_event(action, k)
		if entry.has("pad"):
			var j := InputEventJoypadButton.new()
			j.button_index = int(entry["pad"]) as JoyButton
			InputMap.action_add_event(action, j)

static func bind(action: String, ev: InputEvent) -> void:
	var binds: Dictionary = Profile.setting("bindings")
	var entry: Dictionary = binds.get(action, {})
	if ev is InputEventKey:
		entry["key"] = (ev as InputEventKey).physical_keycode
	elif ev is InputEventJoypadButton:
		entry["pad"] = (ev as InputEventJoypadButton).button_index
	binds[action] = entry
	Profile.set_setting("bindings", binds)
	apply_bindings()

static func describe(action: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			parts.append(OS.get_keycode_string((ev as InputEventKey).physical_keycode))
		elif ev is InputEventJoypadButton:
			parts.append("Pad %d" % (ev as InputEventJoypadButton).button_index)
		elif ev is InputEventJoypadMotion:
			parts.append("Axis %d" % (ev as InputEventJoypadMotion).axis)
	return " / ".join(parts)
