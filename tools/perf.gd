extends Node
## Sim CPU budget at target density: 60 enemies + overflow, 600 ticks.
## (Render frame time is measured separately by capture runs on real hardware.)

func run() -> int:
	var sim: Sim = TestWorld.make(self, 9, 1800.0, false)
	Dev.god_mode = true
	Dev.set_clock(1800.0 - 1690.0)
	Run.pending_threshold = -1
	sim.spawning_enabled = false
	var placed: int = 0
	var ids: Array[StringName] = [&"drone", &"brute", &"flyer", &"gunner", &"slammer", &"lancer"]
	while placed < 60:
		if sim.spawner.spawn_near(ids[placed % ids.size()]) != null:
			placed += 1
	var bot := BotBrain.new()
	var times: Array = []
	var live_sum: int = 0
	for i: int in 600:
		Run.pending_threshold = -1
		var guard: int = 0
		while sim.live_enemies() < 60 and guard < 40:
			sim.spawner.spawn_near(ids[(i + guard) % ids.size()])
			guard += 1
		live_sum += sim.live_enemies()
		var t0: int = Time.get_ticks_usec()
		sim.step_with_packed(bot.next_input(sim))
		times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	times.sort()
	var sum: float = 0.0
	for v: float in times:
		sum += v
	print("perf sim: avg_live=%.1f overflow=%s ticks=600 avg=%.3fms p99=%.3fms max=%.3fms (budget 16.6ms/frame)" % [live_sum / 600.0, str(Run.clock.overflow), sum / times.size(), times[int(times.size() * 0.99)], times[-1]])
	Dev.god_mode = false
	return 0
