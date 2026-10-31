class_name DevPanel
extends PanelContainer
## F1 (debug builds): buttons over the same Dev API the bot and capture use.

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiStyle.theme()
	position = Vector2(20, 140)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiStyle.label("DEV", 18, UiStyle.WARN))
	var acts: Array = [
		["Clock → 20:00", func() -> void: Dev.set_clock(1200.0)],
		["Clock → 2:00 (overflow)", func() -> void: Dev.set_clock(120.0)],
		["Trigger next threshold", func() -> void: Dev.trigger_threshold(Run.clock.next_threshold)],
		["Grant Weight", func() -> void: Dev.grant_adaptation(&"weight")],
		["Grant Lift", func() -> void: Dev.grant_adaptation(&"lift")],
		["Warp Leadfall", func() -> void: Dev.warp(&"leadfall")],
		["Warp Skyreach", func() -> void: Dev.warp(&"skyreach")],
		["Warp Bloom's Lair", func() -> void: Dev.warp(&"bloom_lair")],
		["Spawn 10 drones", func() -> void: Dev.spawn(&"drone", 10)],
		["Trigger fade", func() -> void: Dev.trigger_fade()],
		["God mode toggle", func() -> void: Dev.god_mode = not Dev.god_mode],
		["Perf report 5 s", func() -> void: Dev.perf_report(5.0)],
	]
	for a: Array in acts:
		var b := UiStyle.button(a[0], a[1])
		b.add_theme_font_size_override("font_size", 16)
		v.add_child(b)

func _unhandled_input(e: InputEvent) -> void:
	if Dev.enabled and e.is_action_pressed("dev_panel"):
		visible = not visible
