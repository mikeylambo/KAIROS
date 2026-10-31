class_name RunSetup
extends Control
## Seed (random / daily) and restraints, then begin.

signal start(cfg: Dictionary)
signal back()

var daily: bool = false
var no_transmit: bool = false
var half_time: bool = false
var box: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	_build()

static func daily_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

func _build() -> void:
	for c: Node in get_children():
		c.queue_free()
	var panel := PanelContainer.new()
	add_child(panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UiStyle.label("A NEW LIFE", 36, Color.WHITE))
	box.add_child(UiStyle.label("Restraints narrow the life; they never add power.", 18, UiStyle.DIM))
	var go := UiStyle.button("Begin", _begin)
	box.add_child(go)
	box.add_child(UiStyle.button("Seed: %s" % ("daily (%d)" % daily_seed() if daily else "random"), func() -> void:
		daily = not daily
		_build()))
	box.add_child(UiStyle.button("No transmission: %s" % ("on" if no_transmit else "off"), func() -> void:
		no_transmit = not no_transmit
		_build()))
	box.add_child(UiStyle.button("Half a life (15:00): %s" % ("on" if half_time else "off"), func() -> void:
		half_time = not half_time
		_build()))
	box.add_child(UiStyle.button("Back", func() -> void: back.emit()))
	panel.position = get_viewport_rect().size * 0.5 - Vector2(260, 260)
	go.call_deferred("grab_focus")

func _begin() -> void:
	Audio.play(&"ui_select")
	var r: Array = []
	if no_transmit:
		r.append("no_transmit")
	if half_time:
		r.append("half_time")
	var seed_v: int = daily_seed() if daily else int(Time.get_unix_time_from_system()) % 1000000
	start.emit({"seed": seed_v, "clock": Tuning.t.clock_start, "restraints": r, "daily": daily})

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.emit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#07080d"))
