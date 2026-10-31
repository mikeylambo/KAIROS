class_name PostFx
extends CanvasLayer
## Drives the post shader from Events. Respects flash intensity setting
## (0 → inversion replaced by a brightness pulse).

var rect: ColorRect
var mat: ShaderMaterial
var flash_v: float = 0.0
var beam: bool = false
var fade: float = 0.0
var t: float = 0.0
var crack_boost: float = 0.0

func _ready() -> void:
	layer = 40
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://scripts/fx/shaders/post.gdshader")
	rect.material = mat
	add_child(rect)
	Events.flash.connect(func(a: float) -> void: flash_v = maxf(flash_v, a))
	Events.beam_started.connect(func(_p: Vector2) -> void: beam = true)
	Events.beam_ended.connect(func(_p: Vector2, _f: bool) -> void: beam = false)
	Events.world_break.connect(func(_p: Vector2) -> void: crack_boost = 1.0)
	Events.dimension_marked.connect(func(_id: StringName) -> void: crack_boost = 1.0)

func _process(delta: float) -> void:
	t += delta
	var fl: float = float(Profile.setting("flash"))
	mat.set_shader_parameter("invert", flash_v * fl if flash_v > 0.5 else 0.0)
	mat.set_shader_parameter("pulse", flash_v * (1.0 - fl) * 0.5)
	flash_v = 0.0 if flash_v > 0.5 else maxf(0.0, flash_v - delta * 6.0)
	var over: bool = Run.clock.overflow and Run.active
	mat.set_shader_parameter("chroma", (1.0 if over else 0.0) + crack_boost * 0.6)
	mat.set_shader_parameter("cracks", clampf((0.35 if over else 0.0) + crack_boost, 0.0, 1.0))
	crack_boost = maxf(0.0, crack_boost - delta * 1.5)
	mat.set_shader_parameter("darken", 1.0 if beam else 0.0)
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("time_s", t)
