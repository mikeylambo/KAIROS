class_name LegacyScreen
extends Control
## Bittersweet, shareable summary. Never "GAME OVER".

signal retry()
signal codex()
signal title()

var summary: Dictionary = {}
var t: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	var vs: Vector2 = get_viewport_rect().size
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	var res: String = String(summary.get("result", ""))
	var head: String = "THE THREAT ENDED" if res == "success" else ("ABANDONED" if res == "abandoned" else "THE FADE CAME FIRST")
	col.add_child(UiStyle.label("LEGACY", 20, UiStyle.CYAN))
	col.add_child(UiStyle.label(head, 44, Color.WHITE))
	var line: String = String(summary.get("fade_line", ""))
	if line != "":
		col.add_child(UiStyle.label("“%s”" % line, 22, UiStyle.DIM))
	col.add_child(UiStyle.label(" ", 10))
	col.add_child(_row("PEAK POWER", "%.2f" % float(summary.get("peak_power", 0.0))))
	var tt: float = float(summary.get("threat_time", -1.0))
	var tr: String = String(summary.get("threat_result", "unended"))
	var tr_text: String = "ended early at %s" % UiStyle.fmt_clock(tt) if tr == "ended_early" else ("ended in the Fade Fight" if tr == "ended_fade_fight" else "not ended")
	col.add_child(_row("THE BLOOM", tr_text))
	var marked: Array = summary.get("marked", [])
	col.add_child(_row("DIMENSIONS MARKED", ", ".join(PackedStringArray(marked)) if marked.size() > 0 else "—"))
	col.add_child(_row("LONGEST CHAIN", "%d" % int(summary.get("longest_chain", 0))))
	var ins: Array = summary.get("insights", [])
	col.add_child(_row("INSIGHTS", ", ".join(PackedStringArray(ins.map(func(x: Variant) -> String: return String(x).replace("_", " ")))) if ins.size() > 0 else "—"))
	col.add_child(_row("SEED", "%d" % int(summary.get("seed", 0))))
	col.add_child(UiStyle.label(" ", 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var b := UiStyle.button("Live again", func() -> void: retry.emit())
	row.add_child(b)
	row.add_child(UiStyle.button("Codex", func() -> void: codex.emit()))
	row.add_child(UiStyle.button("Title", func() -> void: title.emit()))
	col.position = Vector2(vs.x * 0.12, vs.y * 0.12)
	b.call_deferred("grab_focus")

func _row(k: String, v: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var a := UiStyle.label(k, 18, UiStyle.DIM)
	a.custom_minimum_size = Vector2(320, 0)
	h.add_child(a)
	h.add_child(UiStyle.label(v, 26, Color.WHITE, true))
	return h

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)]),
		PackedColorArray([Color("#f2f3f7"), Color("#f2f3f7"), Color("#0a0b12"), Color("#0a0b12")]))
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05, minf(0.92, t * 0.8)))
	for k: int in 30:
		var mt: float = fposmod(t * 0.05 + k * 0.033, 1.0)
		draw_circle(Vector2(vs.x * (0.62 + 0.3 * fposmod(k * 0.37, 1.0)), vs.y * (1.0 - mt)), 2.0, Color(1.4, 1.5, 1.7, (1.0 - mt) * 0.6))
