class_name SettingsScreen
extends Control
## Accessibility + audio + full remapping (KBM and pad). Persisted on change.

signal back()

const ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down", "jump", "burst", "light", "heavy", "transmit", "guard", "ki", "burst_field", "map", "pause"]

var listening: String = ""
var scroll: ScrollContainer
var col: VBoxContainer
var status: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	_build()

func _build(focus_idx: int = 0) -> void:
	for c: Node in get_children():
		c.queue_free()
	var vs: Vector2 = get_viewport_rect().size
	scroll = ScrollContainer.new()
	scroll.position = Vector2(vs.x * 0.1, 40)
	scroll.size = Vector2(vs.x * 0.8, vs.y - 80)
	add_child(scroll)
	col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)
	col.add_child(UiStyle.label("SETTINGS", 40, Color.WHITE))
	status = UiStyle.label("", 18, UiStyle.WARN)
	col.add_child(status)
	_toggle("Numeric clock", "numeric_clock")
	_toggle("Guard: toggle instead of hold", "guard_toggle")
	_toggle("Beam: toggle instead of hold", "beam_toggle")
	_toggle("Subtitles", "subtitles")
	_toggle("Fullscreen", "fullscreen")
	_cycle("Screen shake", "shake", [0.0, 0.25, 0.5, 0.75, 1.0])
	_cycle("Flash / inversion intensity", "flash", [0.0, 0.25, 0.5, 0.75, 1.0])
	_cycle("Game speed", "game_speed", [0.7, 0.85, 1.0])
	_cycle("Master volume", "master", [0.0, 0.25, 0.5, 0.75, 1.0])
	_cycle("Music volume", "music", [0.0, 0.25, 0.5, 0.75, 1.0])
	_cycle("SFX volume", "sfx", [0.0, 0.25, 0.5, 0.75, 1.0])
	col.add_child(UiStyle.label("CONTROLS — select, then press a key or pad button", 18, UiStyle.CYAN))
	for a: String in ACTIONS:
		var b := UiStyle.button("%s:  %s" % [a.replace("_", " "), Settings.describe(a)], func() -> void:
			listening = a
			status.text = "Press a key or pad button for %s (Esc cancels)" % a)
		b.custom_minimum_size = Vector2(700, 0)
		col.add_child(b)
	col.add_child(UiStyle.button("Back", func() -> void: back.emit()))
	var focusables: Array = col.get_children().filter(func(n: Node) -> bool: return n is Button)
	if focusables.size() > 0:
		(focusables[clampi(focus_idx, 0, focusables.size() - 1)] as Button).call_deferred("grab_focus")

func _focus_index() -> int:
	var f: Control = get_viewport().gui_get_focus_owner()
	var i: int = 0
	for n: Node in col.get_children():
		if n is Button:
			if n == f:
				return i
			i += 1
	return 0

func _toggle(label_text: String, key: String) -> void:
	col.add_child(UiStyle.button("%s: %s" % [label_text, "on" if Profile.setting(key) else "off"], func() -> void:
		var idx: int = _focus_index()
		Profile.set_setting(key, not Profile.setting(key))
		Settings.apply_all()
		_build(idx)))

func _cycle(label_text: String, key: String, values: Array) -> void:
	var cur: float = float(Profile.setting(key))
	col.add_child(UiStyle.button("%s: %d%%" % [label_text, int(round(cur * 100.0))], func() -> void:
		var idx: int = _focus_index()
		var i: int = 0
		for k: int in values.size():
			if absf(float(values[k]) - cur) < 0.01:
				i = k
		Profile.set_setting(key, values[(i + 1) % values.size()])
		Settings.apply_all()
		_build(idx)))

func _input(e: InputEvent) -> void:
	if listening == "":
		if e.is_action_pressed("ui_cancel"):
			back.emit()
		return
	if not e.is_pressed():
		return
	if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_ESCAPE:
		listening = ""
		status.text = ""
		get_viewport().set_input_as_handled()
		return
	if e is InputEventKey or e is InputEventJoypadButton:
		var idx: int = _focus_index()
		Settings.bind(listening, e)
		listening = ""
		get_viewport().set_input_as_handled()
		_build(idx)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#07080d"))
