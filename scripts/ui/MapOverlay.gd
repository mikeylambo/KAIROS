class_name MapOverlay
extends Control
## Multiverse map. Game keeps running at 0.15× (clock too). Pick a node, then
## Warp (−5 s, instant) or Corridor (free, slow flight).

signal closed()

var buttons: Dictionary = {}
var choice_box: HBoxContainer
var selected: StringName = &""
var t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func open() -> void:
	visible = true
	selected = &""
	_build()

func close() -> void:
	visible = false
	closed.emit()

func _build() -> void:
	for c: Node in get_children():
		c.queue_free()
	buttons.clear()
	var vs: Vector2 = get_viewport_rect().size
	var title := UiStyle.label("MULTIVERSE", 30, UiStyle.CYAN)
	title.position = Vector2(80, 60)
	add_child(title)
	var hint := UiStyle.label("Time flows at 0.15×  ·  Warp costs 5 s  ·  The Corridor is free but slow", 18, UiStyle.DIM)
	hint.position = Vector2(80, 104)
	add_child(hint)
	var first: Button = null
	for id: StringName in Multiverse.destinations():
		var d: DimensionDef = Multiverse.def(id)
		var b := Button.new()
		var tag: String = ""
		if id == Multiverse.current:
			tag = "  · HERE"
		var band: int = Multiverse.band_of(id)
		b.text = "%s\nband %d  ·  %s%s" % [d.display_name, band, d.rule_text, tag]
		b.custom_minimum_size = Vector2(300, 84)
		b.position = Vector2(d.map_pos.x * vs.x - 150, d.map_pos.y * vs.y - 42)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_pick.bind(id))
		b.disabled = id == Multiverse.current
		add_child(b)
		buttons[id] = b
		if first == null and not b.disabled:
			first = b
	choice_box = HBoxContainer.new()
	choice_box.position = Vector2(vs.x * 0.5 - 330, vs.y - 160)
	choice_box.add_theme_constant_override("separation", 20)
	add_child(choice_box)
	var close_b := UiStyle.button("Close  (M)", close)
	close_b.position = Vector2(80, vs.y - 120)
	add_child(close_b)
	if first:
		first.grab_focus()

func _pick(id: StringName) -> void:
	selected = id
	for c: Node in choice_box.get_children():
		c.queue_free()
	var w := UiStyle.button("Warp  −5 s", func() -> void:
		Run.command("warp", String(selected))
		close())
	var c2 := UiStyle.button("Fly the Corridor", func() -> void:
		Run.command("corridor", String(selected))
		close())
	choice_box.add_child(w)
	choice_box.add_child(c2)
	w.grab_focus()
	Audio.play(&"ui_select")

func _process(delta: float) -> void:
	t += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.01, 0.01, 0.03, 0.86))
	var ids: Array[StringName] = Multiverse.destinations()
	var cor: Vector2 = Multiverse.def(&"corridor").map_pos * vs
	for id: StringName in ids:
		var p: Vector2 = Multiverse.def(id).map_pos * vs
		draw_dashed_line(cor, p, Color(0.6, 0.55, 1.0, 0.35), 2.0, 10.0)
	draw_circle(cor, 10.0, Color(0.6, 0.55, 1.0, 0.8))
	draw_string(UiStyle.sans(), cor + Vector2(-80, 34), "the Corridor", HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(0.7, 0.7, 1.0, 0.8))
	for id: StringName in ids:
		var p2: Vector2 = Multiverse.def(id).map_pos * vs
		var r: float = 60.0
		if id == Multiverse.current:
			draw_arc(p2, r + 6.0 * sin(t * 3.0), 0, TAU, 48, UiStyle.CYAN, 2.0)
		if Multiverse.is_consumed(id) or id == &"bloom_lair":
			for k: int in 7:
				var a: float = k * TAU / 7.0 + t * 0.2
				draw_polyline(PackedVector2Array([p2 + Vector2(cos(a), sin(a)) * r, p2 + Vector2(cos(a + 0.3), sin(a + 0.3)) * (r + 30.0), p2 + Vector2(cos(a + 0.1), sin(a + 0.1)) * (r + 52.0)]), Color(1.0, 0.25, 0.85, 0.8), 2.0)
		if Multiverse.marked.has(id):
			for k2: int in 6:
				var x: float = p2.x - r + k2 * 24.0
				draw_line(Vector2(x, p2.y - r), Vector2(x - 16.0, p2.y + r), Color(0.55, 0.57, 0.62, 0.9), 3.0)

func _unhandled_input(e: InputEvent) -> void:
	if visible and (e.is_action_pressed("map") or e.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()
