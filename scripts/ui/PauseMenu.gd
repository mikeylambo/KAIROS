class_name PauseMenu
extends Control
## True pause (clock stops). Restart and Quit ask for confirmation; quitting
## records the run as abandoned (Codex is kept).

signal resume()
signal restart()
signal quit_title()

var box: VBoxContainer
var reason: String = ""
var confirm_action: String = ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func open(why: String = "") -> void:
	reason = why
	visible = true
	_menu()

func _menu() -> void:
	for c: Node in get_children():
		c.queue_free()
	var vs: Vector2 = get_viewport_rect().size
	var panel := PanelContainer.new()
	add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UiStyle.label("PAUSED", 34, Color.WHITE))
	if reason != "":
		box.add_child(UiStyle.label(reason, 18, UiStyle.WARN))
	box.add_child(UiStyle.label("Clock stopped at %s" % UiStyle.fmt_clock(Run.clock.remaining), 18, UiStyle.DIM, true))
	var r := UiStyle.button("Resume", func() -> void:
		visible = false
		resume.emit())
	box.add_child(r)
	box.add_child(UiStyle.button("Numeric clock: %s" % ("on" if Profile.setting("numeric_clock") else "off"), func() -> void:
		Profile.set_setting("numeric_clock", not Profile.setting("numeric_clock"))
		_menu()))
	box.add_child(UiStyle.button("Restart run", func() -> void: _confirm("restart")))
	box.add_child(UiStyle.button("Quit to title", func() -> void: _confirm("quit")))
	panel.position = vs * 0.5 - Vector2(220, 200)
	r.call_deferred("grab_focus")

func _confirm(action: String) -> void:
	for c: Node in get_children():
		c.queue_free()
	var vs: Vector2 = get_viewport_rect().size
	var panel := PanelContainer.new()
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UiStyle.label("Abandon this life?", 30, Color.WHITE))
	v.add_child(UiStyle.label("A life is a life — it can't be resumed. Your Codex is kept.", 18, UiStyle.DIM))
	var no := UiStyle.button("Keep living", _menu)
	v.add_child(no)
	v.add_child(UiStyle.button("Abandon", func() -> void:
		visible = false
		if action == "restart":
			restart.emit()
		else:
			quit_title.emit()))
	panel.position = vs * 0.5 - Vector2(300, 120)
	no.call_deferred("grab_focus")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0, 0, 0, 0.55))
