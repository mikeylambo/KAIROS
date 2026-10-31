class_name ChunkAssembler
extends RefCounted
## Builds a dimension's TerrainGrid from its chunk pool by seed.

class Built:
	var grid: TerrainGrid
	var props: Array[Rect2] = []
	var spawns: Array[Vector2] = []
	var chunk_ids: PackedInt32Array = PackedInt32Array()

static func build(d: DimensionDef, rng: RandomNumberGenerator) -> Built:
	var b := Built.new()
	var cw: int = ChunkLibrary.W
	var ch: int = ChunkLibrary.H
	var pool_arr: Array = ChunkLibrary.pool(d.chunk_pool)
	var wide: int = d.chunks_wide
	var tall: int = d.chunks_tall
	if d.chunk_pool == &"bloom_lair" or d.is_corridor:
		wide = 1
		tall = 1
	var grid := TerrainGrid.new()
	grid.setup(cw * wide, ch * tall)
	grid.wrap_x = not (d.chunk_pool == &"bloom_lair")
	grid.wrap_y = not d.grounded
	if d.is_corridor:
		grid.setup(cw * 4, ch)
		grid.wrap_x = true
		grid.wrap_y = true
	for cy: int in tall:
		for cx: int in wide:
			var idx: int = rng.randi_range(0, pool_arr.size() - 1)
			b.chunk_ids.append(idx)
			_stamp(b, grid, pool_arr[idx], cx * cw, cy * ch)
	b.grid = grid
	return b

static func _stamp(b: Built, g: TerrainGrid, feats: Array, ox: int, oy: int) -> void:
	for f: Array in feats:
		var k: String = f[0]
		match k:
			"floor":
				g.fill(ox + int(f[1]), oy + int(f[2]), int(f[3]), ChunkLibrary.H - int(f[2]), TerrainGrid.SOLID)
			"solid":
				g.fill(ox + int(f[1]), oy + int(f[2]), int(f[3]), int(f[4]), TerrainGrid.SOLID)
			"oneway":
				g.fill(ox + int(f[1]), oy + int(f[2]), int(f[3]), int(f[4]), TerrainGrid.ONEWAY)
			"prop":
				b.props.append(Rect2((ox + float(f[1])) * TerrainGrid.T, (oy + float(f[2])) * TerrainGrid.T,
					float(f[3]) * TerrainGrid.T, float(f[4]) * TerrainGrid.T))
			"spawn":
				b.spawns.append(Vector2((ox + float(f[1]) + 0.5) * TerrainGrid.T, (oy + float(f[2]) + 0.5) * TerrainGrid.T))

## Flood fill of empty cells from `start`; returns count reachable (4-neighbour, wrap-aware).
static func reachable_count(g: TerrainGrid, start: Vector2i) -> int:
	var seen := PackedByteArray()
	seen.resize(g.w * g.h)
	var stack: Array[Vector2i] = [start]
	var n: int = 0
	while stack.size() > 0:
		var c: Vector2i = stack.pop_back()
		var x: int = posmod(c.x, g.w) if g.wrap_x else c.x
		var y: int = posmod(c.y, g.h) if g.wrap_y else c.y
		if x < 0 or y < 0 or x >= g.w or y >= g.h:
			continue
		var i: int = y * g.w + x
		if seen[i] == 1 or g.cells[i] == TerrainGrid.SOLID:
			continue
		seen[i] = 1
		n += 1
		stack.append(Vector2i(x + 1, y))
		stack.append(Vector2i(x - 1, y))
		stack.append(Vector2i(x, y + 1))
		stack.append(Vector2i(x, y - 1))
	return n

static func empty_count(g: TerrainGrid) -> int:
	var n: int = 0
	for v: int in g.cells:
		if v != TerrainGrid.SOLID:
			n += 1
	return n
