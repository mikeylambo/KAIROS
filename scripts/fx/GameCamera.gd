class_name GameCamera
extends Camera2D
## Look-ahead follow, chase framing, state zooms, trauma shake. Works in an
## unwrapped space so wrapping dimensions scroll seamlessly.

const U: float = 32.0
## A chunk (60 tiles) ≈ 1.5 screens → 40 tiles visible at 1920 px.
const BASE_ZOOM: float = 1.5

var sim: Sim
var zen_u: Vector2 = Vector2.ZERO
var gen: int = -1
var trauma: float = 0.0
var zoom_target: float = 1.0
var threshold_zoom: bool = false
var beam_zoom: bool = false
var fade_k: float = 0.0
var shake_rng := RandomNumberGenerator.new()

func _ready() -> void:
	Events.shake.connect(func(px: float) -> void: trauma = minf(18.0, trauma + px))
	Events.beam_started.connect(func(_p: Vector2) -> void: beam_zoom = true)
	Events.beam_ended.connect(func(_p: Vector2, _f: bool) -> void: beam_zoom = false)
	Events.threshold_ready.connect(func(_i: int, _o: Array) -> void: threshold_zoom = true)
	Events.threshold_chosen.connect(func(_id: StringName) -> void: threshold_zoom = false)

## Map a wrapped world position into the camera's unwrapped space.
func vp(p: Vector2) -> Vector2:
	return zen_u + sim.grid.delta(sim.grid.wrap_pos(zen_u), p)

func _process(delta: float) -> void:
	if sim == null or sim.grid == null or sim.zenith == null:
		return
	var z: Zenith = sim.zenith
	if gen != sim.built_generation:
		gen = sim.built_generation
		zen_u = z.pos
		position = z.pos
		reset_smoothing()
	else:
		zen_u += sim.grid.delta(sim.grid.wrap_pos(zen_u), z.pos)
	var look: Vector2 = z.vel.normalized() * minf(1.0, z.vel.length() / (18.0 * U)) * Tuning.t.cam_lookahead * U
	var target: Vector2 = zen_u + look
	var zt: float = 1.0
	var c: ZenithCombat = z.combat
	if c.chase_target != null and c.chase_t > 0:
		var ep: Vector2 = vp(c.chase_target.pos)
		target = (zen_u + ep) * 0.5
		var span: Vector2 = (ep - zen_u).abs() + Vector2(8, 6) * U
		var vs: Vector2 = get_viewport_rect().size
		zt = clampf(minf(vs.x / span.x, vs.y / span.y) / BASE_ZOOM, Tuning.t.cam_chase_zoom_min, 1.0)
	elif sim.bloom != null:
		zt = 0.85
	if Run.clock.overflow:
		zt = minf(zt, Tuning.t.cam_overflow_zoom)
	if beam_zoom:
		zt = minf(zt, Tuning.t.cam_beam_zoom)
	if threshold_zoom:
		zt = Tuning.t.cam_threshold_zoom
		target = zen_u
	if fade_k > 0.0:
		zt = lerpf(zt, Tuning.t.cam_fade_zoom, fade_k)
		target = zen_u
	var k: float = 1.0 - exp(-Tuning.t.cam_smoothing * delta)
	position = position.lerp(target, k)
	var zk: float = 1.0 - exp(-4.0 * delta)
	zoom = Vector2.ONE * lerpf(zoom.x, zt * BASE_ZOOM * (get_viewport_rect().size.x / 1920.0), zk)
	if not sim.grid.wrap_y:
		var vh: float = get_viewport_rect().size.y / zoom.y
		position.y = minf(position.y, sim.grid.size_px().y - vh * 0.5 + 2.0 * U)
	var amt: float = trauma * float(Profile.setting("shake"))
	if Run.clock.overflow:
		amt += 0.8
	offset = Vector2(shake_rng.randf_range(-1, 1), shake_rng.randf_range(-1, 1)) * amt
	trauma = maxf(0.0, trauma - delta * 40.0)
