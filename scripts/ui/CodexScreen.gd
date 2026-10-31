class_name CodexScreen
extends Control
## Discovery record: insights, techniques, adaptations, dimensions, threats.
## Unknown entries stay veiled (Discovery pillar: no spoilers).

signal back()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	var vs: Vector2 = get_viewport_rect().size
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	col.add_child(UiStyle.label("CODEX", 40, Color.WHITE))
	var best: Dictionary = Profile.data["best"]
	col.add_child(UiStyle.label("Best peak power %.2f  ·  longest chain %d  ·  lives lived %d" % [float(best["peak_power"]), int(best["longest_chain"]), (Profile.data["history"] as Array).size()], 18, UiStyle.DIM, true))
	_section(col, "INSIGHTS", "insights", ["transmission_beam", "burst_launcher"])
	_section(col, "TECHNIQUES", "options", ["resonant_beam", "omni_burst_field", "martial_fluency", "phantom_echo", "vessel_expansion", "split_beam", "chase_mastery"])
	_section(col, "ADAPTATIONS", "adaptations", ["weight", "lift"])
	_section(col, "DIMENSIONS", "dimensions", ["threshold", "leadfall", "skyreach", "corridor", "bloom_lair"])
	_section(col, "THREATS", "threats", ["bloom"])
	var b := UiStyle.button("Back", func() -> void: back.emit())
	col.add_child(b)
	col.position = Vector2(vs.x * 0.1, vs.y * 0.08)
	b.call_deferred("grab_focus")

func _section(col: VBoxContainer, title: String, key: String, ids: Array) -> void:
	col.add_child(UiStyle.label(title, 18, UiStyle.CYAN))
	var names: PackedStringArray = PackedStringArray()
	for id: String in ids:
		names.append(id.replace("_", " ").capitalize() if Profile.codex_has(key, id) else "· · ·")
	col.add_child(UiStyle.label("   ".join(names), 22, Color.WHITE))

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.emit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#07080d"))
