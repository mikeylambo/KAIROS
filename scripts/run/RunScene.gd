class_name RunScene
extends Node
## Hosts one life: Sim + views + HUD + overlays. Drives the 60 Hz step from live
## input (or a replay log), handles pause / focus loss / pad disconnect / map.

signal finished(summary: Dictionary)
signal quit_to_title()
signal restart_requested(cfg: Dictionary)

var config: Dictionary = {}
var sim: Sim
var cam: GameCamera
var hud: Hud
var map: MapOverlay
var pause: PauseMenu
var threshold: ThresholdChoice
var fade: FadeOverlay
var post: PostFx
var zview: ZenithView
var reader: InputReader = InputReader.new()
var paused: bool = false
var director: First60 = null
var bot: Object = null
var summary: Dictionary = {}
var ended: bool = false
var pause_on_focus_loss: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Run.start_run(config)
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var bg := BackgroundView.new()
	bg_layer.add_child(bg)
	var world := Node2D.new()
	world.name = "World"
	add_child(world)
	sim = Sim.new()
	sim.name = "Sim"
	sim.visible = false
	world.add_child(sim)
	cam = GameCamera.new()
	cam.sim = sim
	world.add_child(cam)
	cam.make_current()
	var terrain := TerrainView.new()
	terrain.cam = cam
	world.add_child(terrain)
	var ev := EnemyView.new()
	ev.cam = cam
	world.add_child(ev)
	zview = ZenithView.new()
	zview.cam = cam
	world.add_child(zview)
	var fx := FxLayer.new()
	fx.cam = cam
	world.add_child(fx)
	bg.cam = cam
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.environment = e
	add_child(env)
	post = PostFx.new()
	add_child(post)
	var ui := CanvasLayer.new()
	ui.layer = 50
	add_child(ui)
	hud = Hud.new()
	hud.cam = cam
	ui.add_child(hud)
	threshold = ThresholdChoice.new()
	ui.add_child(threshold)
	map = MapOverlay.new()
	map.closed.connect(func() -> void:
		Run.command("map", false)
		reader.discard_for(6))
	ui.add_child(map)
	pause = PauseMenu.new()
	pause.resume.connect(func() -> void:
		paused = false
		reader.discard_for(6))
	pause.restart.connect(_restart)
	pause.quit_title.connect(_abandon)
	ui.add_child(pause)
	ui.add_child(DevPanel.new())
	fade = FadeOverlay.new()
	fade.post = post
	fade.zview = zview
	fade.cam = cam
	fade.done.connect(func() -> void: finished.emit(summary))
	ui.add_child(fade)
	Events.run_finished.connect(_on_finished)
	Input.joy_connection_changed.connect(_on_joy)
	sim.step_with_packed(InputLog.pack(0, Vector2.ZERO))
	if config.get("tutorial", false):
		director = First60.new()
		director.setup(sim, hud)
		sim.director = director
	Audio.cue_for_dimension(Multiverse.current)

func _exit_tree() -> void:
	if director:
		director.teardown()
	if Run.sim == sim:
		Run.active = false

func _on_finished(s: Dictionary) -> void:
	summary = s
	ended = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not ended and pause_on_focus_loss:
		open_pause("Window lost focus")

func _on_joy(_device: int, connected: bool) -> void:
	if not connected and not ended:
		open_pause("Controller disconnected — reconnect to continue")

func open_pause(why: String = "") -> void:
	if ended or threshold.visible:
		return
	paused = true
	pause.open(why)

func _restart() -> void:
	_record_abandon()
	var c: Dictionary = config.duplicate()
	c.erase("tutorial")
	restart_requested.emit(c)

func _abandon() -> void:
	_record_abandon()
	quit_to_title.emit()

func _record_abandon() -> void:
	if Run.active:
		Run.active = false
		var s: Dictionary = Run.summary()
		s["result"] = "abandoned"
		Profile.record_run(s)

func _unhandled_input(e: InputEvent) -> void:
	if ended:
		return
	if e.is_action_pressed("pause") and not map.visible and not threshold.visible:
		if paused:
			pause.visible = false
			paused = false
		else:
			open_pause()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("map") and not paused and not threshold.visible and not map.visible and not Multiverse.fade_fight:
		Run.command("map", true)
		map.open()
		get_viewport().set_input_as_handled()

func _physics_process(_d: float) -> void:
	if paused or ended:
		return
	var v: int
	if bot != null:
		v = bot.next_input(sim)
	elif Run.is_replay():
		v = Run.input_log.frames[Run.tick] if Run.tick < Run.input_log.frames.size() else 0
	elif threshold.visible or map.visible:
		v = InputLog.pack(0, Vector2.ZERO)
	else:
		v = reader.read()
	sim.step_with_packed(v)
