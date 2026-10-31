class_name FadeOverlay
extends Control
## The fade: dissolve to white, silence → single note, the fade line typed out.

signal done()

var line: String = ""
var t: float = -1.0
var post: PostFx
var zview: ZenithView
var cam: GameCamera

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.faded.connect(func(l: String) -> void:
		line = l
		t = 0.0
		Events.line_spoken.emit(""))

func _process(delta: float) -> void:
	if t < 0.0:
		_fade_fight_feedback()
		return
	t += delta
	var k: float = clampf(t / 3.0, 0.0, 1.0)
	if zview:
		zview.dissolve = k
	if cam:
		cam.fade_k = k
	if post:
		post.fade = clampf((t - 1.5) / 2.5, 0.0, 0.85)
	queue_redraw()
	if t > 9.0 or (t > 4.0 and Input.is_action_just_pressed("ui_accept")):
		t = -100.0
		done.emit()

func _fade_fight_feedback() -> void:
	if Run.clock.phase == RunClock.Phase.FADE_FIGHT and zview:
		var k: float = 1.0 - Run.clock.fade_left / maxf(1.0, Run.clock.fade_len)
		zview.dissolve = k * 0.5
		Audio.set_fade_progress(k)

func _draw() -> void:
	if t < 0.0:
		return
	var vs: Vector2 = get_viewport_rect().size
	var shown: int = int(clampf((t - 3.0) * 22.0, 0.0, float(line.length())))
	var a: float = clampf(t - 3.0, 0.0, 1.0)
	draw_string(UiStyle.sans(), Vector2(0, vs.y * 0.5), line.substr(0, shown), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 38, Color(0.05, 0.05, 0.08, a))
