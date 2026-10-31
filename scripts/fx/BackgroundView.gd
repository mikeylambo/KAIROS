class_name BackgroundView
extends Node2D
## Five procedural parallax layers per dimension (manifest art replaces any layer).
## Lower contrast/saturation than the gameplay plane.

var cam: GameCamera
var dim: DimensionDef
var layers: Array = []  # per layer: Array of [Rect2|Vector2, Color, kind]
var textures: Array[Texture2D] = []
var t: float = 0.0
var built_id: StringName = &""
var beam_on: bool = false
var beam_dark: float = 0.0

func _ready() -> void:
	Events.beam_started.connect(func(_p: Vector2) -> void: beam_on = true)
	Events.beam_ended.connect(func(_p: Vector2, _f: bool) -> void: beam_on = false)

const FACTORS: Array[float] = [0.0, 0.08, 0.2, 0.38, 0.6]

func _process(delta: float) -> void:
	t += delta
	beam_dark = move_toward(beam_dark, 1.0 if beam_on else 0.0, delta * 8.0)
	if cam and cam.sim and Multiverse.current != built_id:
		_build()
	queue_redraw()

func _build() -> void:
	built_id = Multiverse.current
	dim = Multiverse.def()
	layers.clear()
	textures.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(built_id)
	for i: int in 5:
		var key: StringName = StringName("bg_%s_%d" % [built_id, i])
		var p: String = Tuning.assets.resolve(key)
		textures.append(load(p) if p != "" else null)
		layers.append(_gen_layer(i, rng))

## Atmospheric perspective: far layers sit close to the haze colour (low contrast),
## nearer layers darken toward the palette's deepest tone. Desaturated ~25%.
func _col(i: int) -> Color:
	var haze: Color = _haze()
	var deep: Color = dim.palette[0].lerp(Color(0.12, 0.12, 0.15), 0.25)
	return haze.lerp(deep, 0.18 + 0.17 * float(i))

func _haze() -> Color:
	var h: Color = dim.palette[2].lerp(dim.palette[3], 0.35)
	var g: float = h.get_luminance()
	return h.lerp(Color(g, g, g), 0.25).darkened(0.25)

func _gen_layer(i: int, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	if i == 0:
		return out
	var width: float = 4096.0
	match dim.id:
		&"threshold", &"bloom_lair":
			var x: float = 0.0
			while x < width:
				var w: float = rng.randf_range(60, 180) * (1.0 + i * 0.3)
				var h: float = rng.randf_range(90, 420) * (0.35 + i * 0.13)
				out.append([Rect2(x, -h, w, h), _col(i), "tower"])
				x += w + rng.randf_range(4, 40)
		&"leadfall":
			var x2: float = 0.0
			while x2 < width:
				var w2: float = rng.randf_range(120, 300)
				var h2: float = rng.randf_range(200, 700) * (0.5 + i * 0.2)
				out.append([Rect2(x2, -h2, w2, h2), _col(i), "slab"])
				x2 += w2 + rng.randf_range(40, 160)
		&"skyreach":
			for k: int in 18:
				out.append([Rect2(rng.randf_range(0, width), rng.randf_range(-500, 200), rng.randf_range(160, 420) * (0.6 + i * 0.2), rng.randf_range(40, 90)), _haze().lightened(0.35 - 0.06 * i), "cloud"])
		&"corridor":
			for k: int in 90:
				out.append([Rect2(rng.randf_range(0, width), rng.randf_range(-700, 700), rng.randf_range(20, 160) * i, 1.0 + i * 0.5), _col(4).lerp(Color("#3FF6FF"), rng.randf() * 0.4), "streak"])
	return out

func _draw() -> void:
	if dim == null or cam == null:
		return
	var vs: Vector2 = get_viewport_rect().size
	var top: Color = dim.palette[0].lerp(Color.BLACK, 0.2)
	var bot: Color = _haze()
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(vs.x, 0), Vector2(vs.x, vs.y), Vector2(0, vs.y)])
	draw_polygon(pts, PackedColorArray([top, top, bot, bot]))
	if Run.clock.overflow:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.25, 0.85, 0.06 + 0.03 * sin(t * 6.0)))
	for i: int in range(1, 5):
		var f: float = FACTORS[i]
		var off: Vector2 = -cam.position * f
		if textures[i] != null:
			var tex: Texture2D = textures[i]
			var tw: float = tex.get_width() * (vs.y / tex.get_height())
			var ox: float = fposmod(off.x, tw)
			for k: int in range(-1, int(vs.x / tw) + 2):
				draw_texture_rect(tex, Rect2(k * tw + ox - tw, 0, tw, vs.y), false)
			continue
		var horizon: float = vs.y * (0.42 + 0.08 * i) + off.y * 0.3
		var wrapw: float = 4096.0
		for item: Array in layers[i]:
			var r: Rect2 = item[0]
			var x: float = fposmod(r.position.x + off.x, wrapw) - 200.0
			if x > vs.x + 50.0:
				continue
			var rr := Rect2(x, horizon + r.position.y, r.size.x, r.size.y)
			var c: Color = item[1]
			match String(item[2]):
				"tower":
					draw_rect(Rect2(rr.position, Vector2(rr.size.x, rr.size.y + vs.y)), c)
					if i == 2 or i == 3:
						var wc: Color = Color(1.0, 0.82, 0.55, 0.035 + 0.02 * i)
						var yy: float = rr.position.y + 16.0
						var row: int = 0
						while yy < rr.position.y + vs.y:
							if (row * 7 + int(r.position.x)) % 3 != 0:
								draw_rect(Rect2(rr.position.x + 10.0, yy, rr.size.x - 20.0, 2.0), wc)
							yy += 30.0
							row += 1
				"slab":
					draw_rect(Rect2(rr.position, Vector2(rr.size.x, rr.size.y + vs.y)), c)
					draw_rect(Rect2(rr.position.x, rr.position.y, rr.size.x, 3.0), c.lightened(0.2))
				"cloud":
					var cy: float = vs.y * 0.5 + r.position.y + off.y * 0.5
					var cx: float = x
					draw_circle(Vector2(cx + rr.size.x * 0.3, cy), rr.size.y * 0.8, Color(c, 0.35))
					draw_circle(Vector2(cx + rr.size.x * 0.6, cy - 10.0), rr.size.y, Color(c, 0.35))
					draw_rect(Rect2(cx, cy, rr.size.x, rr.size.y * 0.6), Color(c, 0.35))
				"streak":
					var sy: float = vs.y * 0.5 + r.position.y
					var sx: float = fposmod(r.position.x + off.x - t * 600.0 * f, wrapw) - 200.0
					draw_line(Vector2(sx, sy), Vector2(sx + r.size.x, sy), c, r.size.y)
		if dim.id == &"leadfall" and i == 3:
			var rc: Color = Color(0.75, 0.72, 0.7, 0.18)
			for k: int in 40:
				var rx: float = fposmod(k * 97.0 + off.x * 1.5, vs.x)
				var ry: float = fposmod(k * 53.0 + t * 900.0, vs.y)
				draw_line(Vector2(rx, ry), Vector2(rx - 4.0, ry + 26.0), rc, 1.5)
		if dim.id == &"skyreach" and i == 4:
			for k: int in 24:
				var wx: float = fposmod(k * 151.0 - t * 500.0, vs.x)
				var wy: float = fposmod(k * 89.0, vs.y)
				draw_line(Vector2(wx, wy), Vector2(wx + 60.0, wy), Color(1, 1, 1, 0.12), 1.0)
	draw_rect(Rect2(Vector2.ZERO, vs), Color(dim.palette[0], 0.18))
	if beam_dark > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.4 * beam_dark))
