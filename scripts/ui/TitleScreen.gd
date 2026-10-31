class_name TitleScreen
extends Control
## Zenith floating over the Threshold skyline. First time: any button starts.
## Later: Begin a life / Codex / Settings / Quit.

signal proceed(choice: String)

var t: float = 0.0
var menu: VBoxContainer = null
var accepting: bool = false
var ribbons: Array[Line2D] = []
var skyline: Array[Rect2] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var x: float = -40.0
	while x < 2400.0:
		var w: float = rng.randf_range(50, 160)
		skyline.append(Rect2(x, -rng.randf_range(120, 460), w, 900))
		x += w + rng.randf_range(2, 30)
	var sh: Shader = load("res://scripts/fx/shaders/ribbon.gdshader")
	var tex := GradientTexture1D.new()
	tex.gradient = Gradient.new()
	for i: int in 2:
		var l := Line2D.new()
		l.texture = tex
		l.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		l.width = 26.0
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("end_color", UiStyle.CYAN if i == 0 else UiStyle.MAGENTA)
		l.material = m
		add_child(l)
		ribbons.append(l)
	if Profile.data.get("first_run_done", false):
		_menu()
	Audio.music(&"music_title")
	get_tree().create_timer(0.4).timeout.connect(func() -> void: accepting = true)

func _menu() -> void:
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)
	var b := UiStyle.button("Begin a life", func() -> void: _go("setup"))
	menu.add_child(b)
	menu.add_child(UiStyle.button("Codex", func() -> void: _go("codex")))
	menu.add_child(UiStyle.button("Settings", func() -> void: _go("settings")))
	menu.add_child(UiStyle.button("Quit", func() -> void: _go("quit")))
	menu.position = Vector2(get_viewport_rect().size.x * 0.5 - 160, get_viewport_rect().size.y * 0.68)
	b.call_deferred("grab_focus")

func _go(c: String) -> void:
	Audio.play(&"ui_select")
	proceed.emit(c)

func _unhandled_input(e: InputEvent) -> void:
	if menu != null or not accepting:
		return
	if (e is InputEventKey or e is InputEventJoypadButton or e is InputEventMouseButton) and e.is_pressed():
		accepting = false
		_go("first")

func _process(delta: float) -> void:
	t += delta
	var vs: Vector2 = get_viewport_rect().size
	var c: Vector2 = Vector2(vs.x * 0.5, vs.y * 0.42 + sin(t * 1.4) * 10.0)
	for i: int in 2:
		var pts := PackedVector2Array()
		for k: int in 16:
			pts.append(c + Vector2(-20 - k * 22.0, -40 + i * 14 + sin(t * 2.0 + k * 0.5 + i) * (4.0 + k * 1.6)))
		ribbons[i].points = pts
		(ribbons[i].material as ShaderMaterial).set_shader_parameter("time_s", t)
	queue_redraw()

func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)]),
		PackedColorArray([Color("#0b0f1c"), Color("#0b0f1c"), Color("#3a4560"), Color("#3a4560")]))
	for r: Rect2 in skyline:
		var rr := Rect2(r.position + Vector2(fposmod(-t * 6.0, 40.0), vs.y * 0.86), r.size)
		draw_rect(rr, Color("#171d2c"))
		var y: float = rr.position.y + 14.0
		while y < vs.y:
			draw_rect(Rect2(rr.position.x + 6, y, rr.size.x - 12, 2), Color(1, 0.9, 0.7, 0.08))
			y += 20.0
	var c: Vector2 = Vector2(vs.x * 0.5, vs.y * 0.42 + sin(t * 1.4) * 10.0)
	_figure(c)
	draw_string(UiStyle.sans(), Vector2(0, vs.y * 0.17), "K A I R O S", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 96, Color(1, 1, 1, 0.95))
	draw_string(UiStyle.sans(), Vector2(0, vs.y * 0.17 + 48), "a life of thirty minutes", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(UiStyle.CYAN, 0.8))
	if menu == null:
		var a: float = 0.5 + 0.5 * sin(t * 3.0)
		draw_string(UiStyle.sans(), Vector2(0, vs.y * 0.78), "Press any button", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 28, Color(1, 1, 1, a))

func _figure(c: Vector2) -> void:
	var s: float = 3.2
	var cloth := Color(0.03, 0.03, 0.04)
	var skin := Color(0.93, 0.92, 0.95)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -16) * s, c + Vector2(7, -16) * s, c + Vector2(6, 4) * s, c + Vector2(-6, 4) * s]), cloth)
	draw_line(c + Vector2(-3, 6) * s, c + Vector2(-5, 26) * s, cloth, 8.0 * s)
	draw_line(c + Vector2(3, 6) * s, c + Vector2(4, 27) * s, cloth, 8.0 * s)
	draw_line(c + Vector2(-6, -12) * s, c + Vector2(-9, 4) * s, skin, 4.0 * s)
	draw_line(c + Vector2(6, -12) * s, c + Vector2(9, 4) * s, skin, 4.0 * s)
	draw_circle(c + Vector2(0, -26) * s, 6.0 * s, skin)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -31) * s, c + Vector2(5, -32) * s, c + Vector2(7, -28) * s, c + Vector2(-13, -25) * s]), Color(0.08, 0.08, 0.1))
	draw_line(c + Vector2(8, -16) * s, c + Vector2(7, 4) * s, UiStyle.CYAN * 1.6, 2.0)
	draw_line(c + Vector2(-8, -16) * s, c + Vector2(-7, 4) * s, UiStyle.MAGENTA * 1.5, 2.0)
	draw_line(c + Vector2(2, -31) * s, c + Vector2(4, -27) * s, Color(2, 2.4, 2.6, 0.6), 1.5)
	for k: int in 8:
		var mt: float = fposmod(t * 0.5 + k * 0.125, 1.0)
		draw_circle(c + Vector2(-12 - mt * 40.0, -28 - mt * 10.0) * s * 0.5 + Vector2(-20, -40), 3.0 * (1.0 - mt), Color(1.5, 1.5, 1.7, 1.0 - mt))
