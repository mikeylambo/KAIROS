extends GutTest
## Chunk assembler: 20 seeds per dimension, no unreachable pockets, no enemy in terrain.

func test_reachability_20_seeds() -> void:
	for id: StringName in [&"threshold", &"leadfall", &"skyreach"]:
		var d: DimensionDef = load("res://data/dimensions/%s.tres" % id)
		for s: int in 20:
			var rng := RandomNumberGenerator.new()
			rng.seed = s
			var b: ChunkAssembler.Built = ChunkAssembler.build(d, rng)
			var g: TerrainGrid = b.grid
			var start := Vector2i(5, 2)
			assert_ne(g.get_cell(start.x, start.y), TerrainGrid.SOLID)
			var reach: int = ChunkAssembler.reachable_count(g, start)
			assert_eq(reach, ChunkAssembler.empty_count(g), "%s seed %d: every open cell reachable" % [id, s])

func test_no_spawn_inside_terrain() -> void:
	Profile.persist = false
	for id: StringName in [&"threshold", &"leadfall", &"skyreach"]:
		for s: int in 20:
			var sim: Sim = TestWorld.make(self, s, 1800.0, false)
			if id != &"threshold":
				Run.command("warp", String(id))
				TestWorld.step(sim, 1, 0)
			for k: int in 30:
				sim.spawner._spawn_random(false)
			for e: EnemyBase in sim.enemies:
				if e.alive:
					assert_false(sim.grid.rect_blocked(e.pos, e.half), "%s seed %d: %s not in terrain" % [id, s, e.def.id])
			sim.queue_free()
