class_name UiStyle
extends RefCounted
## SLU identity: thin-line glyphs, cyan/magenta/white on near-black glass, mono numerals.

const CYAN := Color("#3FF6FF")
const MAGENTA := Color("#FF3FD8")
const WHITE := Color("#FFFFFF")
const WARN := Color("#FF8A1F")
const GLASS := Color(0.02, 0.02, 0.04, 0.82)
const DIM := Color(0.62, 0.66, 0.74)

static var _mono: Font = null
static var _sans: Font = null

static func mono() -> Font:
	if _mono == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["JetBrains Mono", "Menlo", "Consolas", "DejaVu Sans Mono", "monospace"])
		_mono = f
	return _mono

static func sans() -> Font:
	if _sans == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Inter", "Helvetica Neue", "Segoe UI", "DejaVu Sans", "sans-serif"])
		f.font_weight = 300
		_sans = f
	return _sans

static func panel(border: Color = CYAN, alpha: float = 0.82) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(GLASS.r, GLASS.g, GLASS.b, alpha)
	s.border_color = Color(border.r, border.g, border.b, 0.55)
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 20
	s.content_margin_bottom = 20
	s.shadow_color = Color(border.r, border.g, border.b, 0.12)
	s.shadow_size = 14
	return s

static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = sans()
	t.default_font_size = 22
	var normal := panel(DIM, 0.55)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var focus := panel(CYAN, 0.9)
	focus.content_margin_top = 12
	focus.content_margin_bottom = 12
	focus.border_color = CYAN
	focus.set_border_width_all(2)
	focus.bg_color = Color(0.05, 0.12, 0.14, 0.92)
	var hover := focus.duplicate()
	var pressed := focus.duplicate()
	pressed.bg_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.35)
	for cls: String in ["Button", "OptionButton", "CheckButton"]:
		t.set_stylebox("normal", cls, normal)
		t.set_stylebox("focus", cls, focus)
		t.set_stylebox("hover", cls, hover)
		t.set_stylebox("pressed", cls, pressed)
		t.set_color("font_color", cls, Color(0.85, 0.88, 0.94))
		t.set_color("font_focus_color", cls, WHITE)
		t.set_color("font_hover_color", cls, WHITE)
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_color("font_color", "Label", Color(0.88, 0.9, 0.96))
	var grab := StyleBoxFlat.new()
	grab.bg_color = CYAN
	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(1, 1, 1, 0.15)
	slider.content_margin_top = 2
	slider.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	return t

static func label(text: String, size: int = 22, color: Color = Color(0.88, 0.9, 0.96), mono_font: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if mono_font:
		l.add_theme_font_override("font", mono())
	return l

static func button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 0)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	b.focus_entered.connect(func() -> void: Audio.play(&"ui_move"))
	return b

static func fmt_clock(seconds: float) -> String:
	var s: int = int(ceil(maxf(0.0, seconds)))
	return "%02d:%02d" % [s / 60, s % 60]
