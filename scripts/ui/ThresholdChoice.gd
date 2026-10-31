class_name ThresholdChoice
extends Control
## Modal pick-1-of-3. The game is frozen (Run.is_frozen) until a pick is made.

var cards: HBoxContainer
var title: Label
var t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.threshold_ready.connect(_show)
	Events.threshold_chosen.connect(func(_id: StringName) -> void: visible = false)

func _show(index: int, options: Array) -> void:
	if Run.is_replay():
		return
	visible = true
	t = 0.0
	for c: Node in get_children():
		c.queue_free()
	var vs: Vector2 = get_viewport_rect().size
	title = UiStyle.label(["TEN MINUTES", "TWENTY MINUTES", "TWENTY-EIGHT MINUTES"][mini(index, 2)], 40, Color.WHITE)
	title.position = Vector2(0, vs.y * 0.18)
	title.size = Vector2(vs.x, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := UiStyle.label("Choose what the rest of this life becomes.", 20, UiStyle.DIM)
	sub.position = Vector2(0, vs.y * 0.18 + 60)
	sub.size = Vector2(vs.x, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 28)
	add_child(cards)
	var first: Button = null
	for o: ThresholdOptionDef in options:
		var b := Button.new()
		b.custom_minimum_size = Vector2(380, 300)
		b.text = "%s\n\n%s\n\n%s" % [o.category.to_upper(), o.display_name, o.description]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(func() -> void:
			Audio.play(&"ui_select")
			Run.choose_option(o.id))
		cards.add_child(b)
		if first == null:
			first = b
	cards.position = Vector2(vs.x * 0.5 - (options.size() * 408 - 28) * 0.5, vs.y * 0.36)
	if first:
		first.call_deferred("grab_focus")

func _process(delta: float) -> void:
	t += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.0, 0.0, 0.02, minf(0.7, t * 2.0)))
	var r: float = 200.0 + t * 900.0
	draw_arc(vs * 0.5, r, 0, TAU, 96, Color(1, 1, 1, maxf(0.0, 0.6 - t * 0.5)), 3.0)
