class_name TerrainGrid
extends RefCounted
## Tile collision for custom kinematic movement. 1 tile = 1 u = 32 px.
## 0 empty, 1 solid, 2 one-way (cloud: solid from above only).

const T: float = 32.0
const EMPTY := 0
const SOLID := 1
const ONEWAY := 2

var w: int = 0
var h: int = 0
var cells: PackedByteArray = PackedByteArray()
var wrap_x: bool = true
var wrap_y: bool = false

func setup(width: int, height: int) -> void:
	w = width
	h = height
	cells = PackedByteArray()
	cells.resize(w * h)

func size_px() -> Vector2:
	return Vector2(w * T, h * T)

func get_cell(x: int, y: int) -> int:
	if wrap_x:
		x = posmod(x, w)
	elif x < 0 or x >= w:
		return SOLID
	if wrap_y:
		y = posmod(y, h)
	elif y < 0:
		return EMPTY
	elif y >= h:
		return SOLID
	return cells[y * w + x]

func set_cell(x: int, y: int, v: int) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	cells[y * w + x] = v

func fill(x: int, y: int, ww: int, hh: int, v: int) -> void:
	for yy: int in range(y, y + hh):
		for xx: int in range(x, x + ww):
			set_cell(xx, yy, v)

func solid_at_px(p: Vector2) -> bool:
	return get_cell(int(floor(p.x / T)), int(floor(p.y / T))) == SOLID

func rect_blocked(pos: Vector2, half: Vector2) -> bool:
	var x0: int = int(floor((pos.x - half.x) / T))
	var x1: int = int(floor((pos.x + half.x - 0.01) / T))
	var y0: int = int(floor((pos.y - half.y) / T))
	var y1: int = int(floor((pos.y + half.y - 0.01) / T))
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			if get_cell(x, y) == SOLID:
				return true
	return false

func wrap_pos(p: Vector2) -> Vector2:
	var s: Vector2 = size_px()
	if wrap_x:
		p.x = fposmod(p.x, s.x)
	if wrap_y:
		p.y = fposmod(p.y, s.y)
	return p

## Shortest delta from a to b honoring wrap.
func delta(a: Vector2, b: Vector2) -> Vector2:
	var d: Vector2 = b - a
	var s: Vector2 = size_px()
	if wrap_x:
		d.x = fposmod(d.x + s.x * 0.5, s.x) - s.x * 0.5
	if wrap_y:
		d.y = fposmod(d.y + s.y * 0.5, s.y) - s.y * 0.5
	return d

## Moves an AABB by `motion` (px). Returns {pos, hit_x, hit_floor, hit_ceil}.
## One-way tiles block only downward motion when the box bottom starts above them.
func move(pos: Vector2, half: Vector2, motion: Vector2, drop_through: bool = false) -> Dictionary:
	var res: Dictionary = {"hit_x": false, "hit_floor": false, "hit_ceil": false}
	var steps: int = int(ceil(maxf(absf(motion.x), absf(motion.y)) / 8.0))
	steps = maxi(steps, 1)
	var sx: float = motion.x / steps
	var sy: float = motion.y / steps
	for i: int in steps:
		if sx != 0.0:
			var nx: Vector2 = Vector2(pos.x + sx, pos.y)
			if rect_blocked(nx, half):
				res["hit_x"] = true
				sx = 0.0
			else:
				pos = nx
		if sy != 0.0:
			var ny: Vector2 = Vector2(pos.x, pos.y + sy)
			if rect_blocked(ny, half) or (sy > 0.0 and not drop_through and _oneway_hit(pos, ny, half)):
				if sy > 0.0:
					res["hit_floor"] = true
					pos.y = floor((ny.y + half.y - 0.01) / T) * T - half.y
				else:
					res["hit_ceil"] = true
				sy = 0.0
			else:
				pos = ny
	res["pos"] = wrap_pos(pos)
	return res

func _oneway_hit(from: Vector2, to: Vector2, half: Vector2) -> bool:
	var b0: float = from.y + half.y
	var b1: float = to.y + half.y
	var row: int = int(floor(b1 / T))
	if b0 > row * T + 0.01:
		return false
	var x0: int = int(floor((to.x - half.x) / T))
	var x1: int = int(floor((to.x + half.x - 0.01) / T))
	for x: int in range(x0, x1 + 1):
		if get_cell(x, row) == ONEWAY:
			return true
	return false

func on_floor(pos: Vector2, half: Vector2) -> bool:
	var probe: Vector2 = pos + Vector2(0, 1.0)
	if rect_blocked(probe, half):
		return true
	return _oneway_hit(pos, probe, half)
