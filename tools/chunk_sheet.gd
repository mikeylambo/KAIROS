extends Node
## Renders every authored chunk (8 per slice dimension) into screens/chunks_<dim>.png:
## solid = slate, cloud = white, props = teal, spawn markers = orange.

func run() -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screens"))
	var s: int = 4
	for id: StringName in [&"threshold", &"leadfall", &"skyreach"]:
		var pool: Array = ChunkLibrary.pool(id)
		var img := Image.create(ChunkLibrary.W * s * 4 + 30, ChunkLibrary.H * s * 2 + 20, false, Image.FORMAT_RGBA8)
		img.fill(Color("#07080d"))
		for i: int in pool.size():
			var d := DimensionDef.new()
			d.chunk_pool = id
			var b := ChunkAssembler.Built.new()
			var g := TerrainGrid.new()
			g.setup(ChunkLibrary.W, ChunkLibrary.H)
			ChunkAssembler._stamp(b, g, pool[i], 0, 0)
			var ox: int = (i % 4) * (ChunkLibrary.W * s + 10)
			var oy: int = (i / 4) * (ChunkLibrary.H * s + 10)
			img.fill_rect(Rect2i(ox, oy, ChunkLibrary.W * s, ChunkLibrary.H * s), Color("#1a2133"))
			for y: int in g.h:
				for x: int in g.w:
					var v: int = g.cells[y * g.w + x]
					if v == TerrainGrid.SOLID:
						img.fill_rect(Rect2i(ox + x * s, oy + y * s, s, s), Color("#5a6580"))
					elif v == TerrainGrid.ONEWAY:
						img.fill_rect(Rect2i(ox + x * s, oy + y * s, s, s), Color("#e6eef5"))
			for r: Rect2 in b.props:
				img.fill_rect(Rect2i(ox + int(r.position.x / 32.0) * s, oy + int(r.position.y / 32.0) * s, int(r.size.x / 32.0) * s, int(r.size.y / 32.0) * s), Color("#2a8a9a"))
			for p: Vector2 in b.spawns:
				img.fill_rect(Rect2i(ox + int(p.x / 32.0) * s - 2, oy + int(p.y / 32.0) * s - 2, 5, 5), Color("#FF8A1F"))
		img.save_png(ProjectSettings.globalize_path("res://screens/chunks_%s.png" % id))
		print("chunk_sheet: %s (%d chunks)" % [id, pool.size()])
	return 0
