class_name Hud
extends Control
## HUD per GDD §10: exposure (top-left), chain (top-right, ≥5), optional numeric
## clock, tutorial glyphs, subtitles, name cards, clash meter, toasts.

const U: float = 32.0
var cam: GameCamera
var chain: int = 0
var chain_shown: int = 0
var chain_fade: float = 0.0
var exposure_flash: float = 0.0
var exposure_visible: bool = true
var glyphs: Array[Dictionary] = []  # {text, target:Object|null, world:Vector2, pulse}
var subtitle: String = ""
var subtitle_t: float = 0.0
var card: String = ""
var card_sub: String = ""
var card_t: float = 0.0
var toast_text: String = ""
var toast_t: float = 0.0
var clash: float = -1.0
var map_pulse: float = 0.0
var t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.chain_changed.connect(func(n: int) -> void:
		if n == 0 and chain >= 5:
			chain_fade = 1.5
		chain = n
		if n > 0:
			chain_shown = n)
	Events.adaptation_gained.connect(func(id: StringName) -> void:
		exposure_flash = 1.0
		var d: AdaptationDef = Tuning.adaptation(id)
		show_card("ADAPTED · " + d.display_name.to_upper(), d.description))
	Events.dimension_entered.connect(func(id: StringName) -> void:
		var d: DimensionDef = Multiverse.def(id)
		show_card(d.display_name.to_upper(), d.rule_text))
	Events.dimension_marked.connect(func(id: StringName) -> void:
		show_card("MARKED · " + Multiverse.def(id).display_name.to_upper(), "Weight carried into the open sky."))
	Events.insight_found.connect(func(id: StringName) -> void:
		for d: InsightDef in Run.insights.defs:
			if d.id == id:
				show_card("INSIGHT · " + d.display_name.to_upper(), d.description))
	Events.bloom_phase.connect(func(n: int) -> void:
		if n == 1:
			show_card("THE BLOOM", "It grows in every world you leave."))
	Events.lair_revealed.connect(func() -> void: map_pulse = 3.0)
	Events.line_spoken.connect(func(s: String) -> void:
		if Profile.setting("subtitles"):
			subtitle = s
			subtitle_t = 3.5)
	Events.toast.connect(func(s: String) -> void:
		toast_text = s
		toast_t = 2.5)
	Events.clash_changed.connect(func(v: float) -> void: clash = v)
	Events.threat_ended.connect(func(early: bool) -> void:
		show_card("THREAT ENDED", "The rest of this life is yours." if early else "Nothing left to hold you."))

func show_card(a: String, b: String) -> void:
	card = a
	card_sub = b
	card_t = 2.6

func add_glyph(text: String, target: Object, id: StringName) -> void:
	glyphs.append({"text": text, "target": target, "id": id, "t": 0.0})

func clear_glyph(id: StringName) -> void:
	glyphs = glyphs.filter(func(g: Dictionary) -> bool: return g["id"] != id)

func world_to_screen(p: Vector2) -> Vector2:
	var vs: Vector2 = get_viewport_rect().size
	return (cam.vp(p) - cam.get_screen_center_position()) * cam.zoom + vs * 0.5

func _process(delta: float) -> void:
	t += delta
	chain_fade = maxf(0.0, chain_fade - delta)
	exposure_flash = maxf(0.0, exposure_flash - delta)
	subtitle_t = maxf(0.0, subtitle_t - delta)
	card_t = maxf(0.0, card_t - delta)
	toast_t = maxf(0.0, toast_t - delta)
	map_pulse = maxf(0.0, map_pulse - delta)
	if Run.sim and Run.sim.bloom == null:
		clash = -1.0
	for g: Dictionary in glyphs:
		g["t"] = float(g["t"]) + delta
	queue_redraw()

func _draw() -> void:
	if cam == null or cam.sim == null:
		return
	var vs: Vector2 = get_viewport_rect().size
	var mono: Font = UiStyle.mono()
	var sans: Font = UiStyle.sans()
	if exposure_visible:
		_exposure(Vector2(70, 70), mono)
	var ch: int = chain if chain > 0 else chain_shown
	if (chain >= 5) or chain_fade > 0.0:
		var a: float = 1.0 if chain >= 5 else chain_fade / 1.5
		draw_string(mono, Vector2(vs.x - 260, 92), "%d" % ch, HORIZONTAL_ALIGNMENT_RIGHT, 200, 64, Color(1, 1, 1, a))
		draw_string(sans, Vector2(vs.x - 260, 120), "CHAIN", HORIZONTAL_ALIGNMENT_RIGHT, 200, 16, Color(UiStyle.CYAN, a))
	if Profile.setting("numeric_clock"):
		var secs: float = Run.clock.remaining if Run.clock.phase != RunClock.Phase.FADE_FIGHT else Run.clock.fade_left
		draw_string(mono, Vector2(vs.x * 0.5 - 100, 64), UiStyle.fmt_clock(secs), HORIZONTAL_ALIGNMENT_CENTER, 200, 40, Color(1, 1, 1, 0.9))
	for g: Dictionary in glyphs:
		var target: Object = g["target"]
		var p: Vector2 = Vector2(vs.x * 0.5, vs.y * 0.3)
		if target != null and is_instance_valid(target) and target.alive:
			p = world_to_screen(target.pos) + Vector2(0, -70)
		elif target != null:
			continue
		var pul: float = 1.0 + 0.12 * sin(float(g["t"]) * 8.0)
		draw_circle(p, 26.0 * pul, Color(0, 0, 0, 0.6))
		draw_arc(p, 26.0 * pul, 0, TAU, 32, UiStyle.CYAN, 2.0)
		draw_string(mono, p + Vector2(-40, 9), String(g["text"]), HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color.WHITE)
	if map_pulse > 0.0:
		var k: float = 0.5 + 0.5 * sin(t * 8.0)
		draw_arc(Vector2(vs.x - 80, vs.y - 80), 30.0 + 6.0 * k, 0, TAU, 32, Color(UiStyle.MAGENTA, 0.9), 2.0)
		draw_string(mono, Vector2(vs.x - 120, vs.y - 72), "M", HORIZONTAL_ALIGNMENT_CENTER, 80, 24, Color.WHITE)
	if card_t > 0.0:
		var a2: float = minf(1.0, card_t * 2.0) * minf(1.0, (2.6 - card_t) * 4.0)
		draw_string(sans, Vector2(0, vs.y * 0.2), card, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 44, Color(1, 1, 1, a2))
		draw_line(Vector2(vs.x * 0.5 - 140, vs.y * 0.2 + 16), Vector2(vs.x * 0.5 + 140, vs.y * 0.2 + 16), Color(UiStyle.CYAN, a2), 1.0)
		draw_string(sans, Vector2(0, vs.y * 0.2 + 50), card_sub, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(0.8, 0.85, 0.9, a2))
	if subtitle_t > 0.0 and subtitle != "":
		var a3: float = minf(1.0, subtitle_t)
		var w: float = sans.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 48.0
		draw_rect(Rect2(vs.x * 0.5 - w * 0.5, vs.y * 0.70 - 34, w, 50), Color(0, 0, 0, 0.55 * a3))
		draw_string(sans, Vector2(0, vs.y * 0.70), subtitle, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 30, Color(1, 1, 1, a3))
	if toast_t > 0.0:
		draw_string(sans, Vector2(0, vs.y - 50), toast_text, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 18, Color(UiStyle.WARN, minf(1.0, toast_t)))
	if clash >= 0.0:
		var w: float = 600.0
		var x0: float = vs.x * 0.5 - w * 0.5
		draw_rect(Rect2(x0, vs.y - 170, w, 14), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(x0, vs.y - 170, w * clampf(clash / Tuning.threat.clash_need, 0, 1), 14), UiStyle.CYAN * 1.4)
		draw_rect(Rect2(x0, vs.y - 170, w, 14), Color(1, 1, 1, 0.5), false, 1.0)
		draw_string(mono, Vector2(0, vs.y - 182), "CLASH — MASH U / RT", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 18, Color(1, 1, 1, 0.9))

func _exposure(c: Vector2, mono: Font) -> void:
	var d: DimensionDef = Multiverse.def()
	var r: float = 34.0
	var flash: float = exposure_flash
	draw_circle(c, r + 6.0, Color(0, 0, 0, 0.45))
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.15), 3.0)
	var glyph: String = "—"
	var v: float = 0.0
	if d.adaptation_id != &"":
		var ad: AdaptationDef = Tuning.adaptation(d.adaptation_id)
		glyph = ad.glyph
		v = 1.0 if Run.adaptations.has(d.adaptation_id) else Multiverse.exposure_of(d.id) / Tuning.prog.exposure_full
	if v > 0.0:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * v, 48, (UiStyle.CYAN * 1.5).lerp(Color(3, 3, 3), flash), 3.0)
	draw_string(mono, c + Vector2(-30, 10), glyph, HORIZONTAL_ALIGNMENT_CENTER, 60, 28, Color(1, 1, 1, 0.9))
	var x: float = c.x + r + 20.0
	for a: StringName in Run.adaptations:
		draw_string(mono, Vector2(x, c.y + 8), Tuning.adaptation(a).glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiStyle.MAGENTA * 1.3)
		x += 28.0
