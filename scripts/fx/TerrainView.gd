class_name TerrainView
extends Node2D
## Draws visible tiles (merged into runs), props, craters and Bloom vines.

const T: float = 32.0
var cam: GameCamera

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if cam == null or cam.sim == null or cam.sim.grid == null:
		return
	var s: Sim = cam.sim
	var g: TerrainGrid = s.grid
	var d: DimensionDef = Multiverse.def()
	var vs: Vector2 = get_viewport_rect().size / cam.zoom
	var c: Vector2 = cam.position
	var x0: int = int(floor((c.x - vs.x * 0.5) / T)) - 1
	var x1: int = int(ceil((c.x + vs.x * 0.5) / T)) + 1
	var y0: int = int(floor((c.y - vs.y * 0.5) / T)) - 1
	var y1: int = int(ceil((c.y + vs.y * 0.5) / T)) + 1
	var fill: Color = d.palette[0].lerp(Color(0.02, 0.02, 0.03), 0.55)
	var face: Color = d.palette[1].lerp(Color(0.04, 0.04, 0.06), 0.35)
	var rim: Color = d.palette[4].lerp(Color("#3FF6FF"), 0.25)
	rim.a = 0.85
	var cloud: Color = Color(d.palette[4], 0.85)
	for y: int in range(y0, y1 + 1):
		var x: int = x0
		while x <= x1:
			var v: int = g.get_cell(x, y)
			if v == TerrainGrid.EMPTY:
				x += 1
				continue
			var start: int = x
			while x <= x1 and g.get_cell(x, y) == v:
				x += 1
			var r := Rect2(start * T, y * T, (x - start) * T, T if v == TerrainGrid.SOLID else 10.0)
			if v == TerrainGrid.SOLID:
				var top_open: bool = false
				for k: int in range(start, x):
					if g.get_cell(k, y - 1) != TerrainGrid.SOLID:
						top_open = true
						break
				# Depth shading: lit face fades into the mass over 6 rows; faint seams.
				var depth: int = 0
				while depth < 6 and g.get_cell(start, y - depth - 1) == TerrainGrid.SOLID:
					depth += 1
				draw_rect(r, face.lerp(fill, float(depth) / 6.0))
				if (y % 4) == 0:
					draw_line(r.position, Vector2(r.end.x, r.position.y), Color(1, 1, 1, 0.025), 1.0)
				if top_open:
					for k: int in range(start, x):
						if g.get_cell(k, y - 1) != TerrainGrid.SOLID:
							draw_line(Vector2(k * T, y * T + 0.5), Vector2((k + 1) * T, y * T + 0.5), rim, 2.0)
			else:
				draw_rect(r, cloud)
				draw_line(r.position, Vector2(r.end.x, r.position.y), Color(1, 1, 1, 0.9), 2.0)
				draw_rect(Rect2(r.position + Vector2(0, 10), Vector2(r.size.x, 6)), Color(cloud, 0.35))
	for pr: Rect2 in s.props:
		var p: Vector2 = cam.vp(pr.position)
		var rr := Rect2(p, pr.size)
		draw_rect(Rect2(rr.position + Vector2(rr.size.x * 0.45, rr.size.y), Vector2(rr.size.x * 0.1, 64)), face.darkened(0.3))
		draw_rect(rr, Color(0.08, 0.09, 0.12))
		draw_rect(rr.grow(-6), Color(0.15, 0.4, 0.5, 0.9))
		draw_rect(rr, rim, false, 2.0)
		draw_string(UiStyle.mono(), rr.position + Vector2(14, rr.size.y * 0.62), "KAIROS", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.8))
	for cr: Vector2 in s.craters:
		var p2: Vector2 = cam.vp(cr)
		draw_circle(p2, 22.0, Color(0, 0, 0, 0.35))
		for k: int in 6:
			var a: float = k * TAU / 6.0 + cr.x
			draw_line(p2, p2 + Vector2(cos(a), sin(a)) * 34.0, Color(1, 1, 1, 0.15), 1.5)
	if s.bloom:
		for v: Dictionary in s.bloom.vines:
			var vx: float = cam.vp(Vector2(v["x"], c.y)).x
			if int(v["t"]) > 0:
				var k2: float = 1.0 - float(v["t"]) / float(Tuning.threat.telegraph_f)
				draw_line(Vector2(vx, c.y - vs.y), Vector2(vx, c.y + vs.y), Color(1.0, 0.54, 0.12, 0.25 + 0.5 * k2), 2.0 + 6.0 * k2)
			else:
				draw_rect(Rect2(vx - 38.0, c.y - vs.y, 76.0, vs.y * 2.0), Color(0.85, 0.25, 0.72, 0.85))
				draw_rect(Rect2(vx - 14.0, c.y - vs.y, 28.0, vs.y * 2.0), Color(1.4, 0.6, 1.3, 0.9))
