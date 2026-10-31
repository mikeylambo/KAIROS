extends Node
## Owns: clock/phase/thresholds (RunClock), seeded rng, build, hitstop, power,
## XP/bands, run stats. The only source of gameplay randomness is `rng`.

const U: float = 32.0
const DT: float = 1.0 / 60.0

var clock: RunClock = RunClock.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var build: BuildModifiers = BuildModifiers.new()
var pool: ThresholdPool = ThresholdPool.new()
var insights: Insights = Insights.new()
var input_log: InputLog = InputLog.new()
var config: Dictionary = {}
var active: bool = false
var tick: int = 0
var hitstop: int = 0
var xp: float = 0.0
var peak_power: float = 1.0
var taken: Array[StringName] = []
var adaptations: Array[StringName] = []
var pending_threshold: int = -1
var pending_options: Array[ThresholdOptionDef] = []
var stats: Dictionary = {}
var sim: Node = null

func _ready() -> void:
	clock.threshold_reached.connect(_on_threshold)
	clock.overflow_started.connect(func() -> void: Events.overflow_started.emit())
	clock.fade_fight_started.connect(_on_fade_fight)
	clock.faded.connect(_on_faded)
	insights.discovered.connect(_on_insight)

## cfg keys: seed:int, clock:float (seconds), restraints:Array, tutorial:bool, replay:InputLog
func start_run(cfg: Dictionary) -> void:
	config = cfg.duplicate()
	var seed_v: int = int(cfg.get("seed", 1))
	rng.seed = seed_v
	rng.state = 0
	var start_s: float = float(cfg.get("clock", Tuning.t.clock_start))
	if has_restraint(&"half_time"):
		start_s *= 0.5
	clock.setup(Tuning.t, start_s)
	build = BuildModifiers.new()
	pool.load_all()
	insights.load_all()
	input_log = cfg.get("replay", InputLog.new()) if cfg.has("replay") else InputLog.new()
	tick = 0
	hitstop = 0
	xp = 0.0
	peak_power = 1.0
	taken.clear()
	adaptations.clear()
	pending_threshold = -1
	pending_options.clear()
	stats = {"longest_chain": 0, "kills": 0, "chases": 0, "first_chase_tick": -1,
		"threat_result": "unended", "threat_time": -1.0, "hits_taken": 0, "result": ""}
	active = true
	Multiverse.setup()

func is_replay() -> bool:
	return config.has("replay")

func has_restraint(r: StringName) -> bool:
	var arr: Array = config.get("restraints", [])
	return arr.has(r) or arr.has(String(r))

func is_frozen() -> bool:
	return pending_threshold >= 0 or not active

func power_floor() -> float:
	return PowerCurve.floor_at(Tuning.prog, clock.life_fraction())

func bonus() -> float:
	var b: float = 0.0
	for id: StringName in taken:
		var d: ThresholdOptionDef = pool.get_def(id)
		if d:
			b += d.power_bonus
	for id: StringName in adaptations:
		b += Tuning.adaptation(id).power_bonus
	return b

func power() -> float:
	return power_floor() * (1.0 + bonus())

func level() -> int:
	return int(floor(xp / Tuning.prog.xp_per_level))

func player_band() -> int:
	return PowerCurve.player_band(Tuning.prog, xp)

func add_kill_xp(base: float, dim_band: int) -> void:
	var f: float = PowerCurve.band_factor(Tuning.prog, dim_band, player_band())
	if Multiverse.is_consumed(Multiverse.current):
		f *= 2.0
	xp += base * f

func request_hitstop(frames: int) -> void:
	hitstop = maxi(hitstop, frames)
	Events.hitstop.emit(frames)

func sample_power() -> void:
	peak_power = maxf(peak_power, power())

func note_chain(n: int) -> void:
	stats["longest_chain"] = maxi(int(stats["longest_chain"]), n)

func grant_option(id: StringName) -> void:
	var d: ThresholdOptionDef = pool.get_def(id)
	if d == null or taken.has(id):
		return
	taken.append(id)
	build.set_source("opt_" + String(id), d.effects)
	Profile.codex_add("options", String(id))

func grant_adaptation(id: StringName) -> void:
	if adaptations.has(id):
		return
	var d: AdaptationDef = Tuning.adaptation(id)
	if d == null:
		return
	adaptations.append(id)
	build.set_source("adapt_" + String(id), d.effects)
	Events.adaptation_gained.emit(id)
	Profile.codex_add("adaptations", String(id))

func choose_option(id: StringName) -> void:
	if pending_threshold < 0:
		return
	if not is_replay():
		input_log.command(tick, "choose", String(id))
	grant_option(id)
	pending_threshold = -1
	pending_options.clear()
	Events.threshold_chosen.emit(id)

func command(name: String, arg: Variant) -> void:
	if not is_replay():
		input_log.command(tick, name, arg)
	_apply_command(name, arg)

func apply_logged_commands() -> void:
	if not is_replay():
		return
	for c: Array in input_log.commands_at(tick):
		if String(c[1]) == "choose":
			if pending_threshold >= 0:
				grant_option(StringName(c[2]))
				pending_threshold = -1
				pending_options.clear()
				Events.threshold_chosen.emit(StringName(c[2]))
		else:
			_apply_command(String(c[1]), c[2])

func _apply_command(name: String, arg: Variant) -> void:
	match name:
		"warp":
			Multiverse.warp(StringName(arg))
		"corridor":
			Multiverse.travel_corridor(StringName(arg))
		"map":
			if sim:
				sim.map_open = bool(arg)
				sim.map_acc = 0.0

func _on_threshold(i: int) -> void:
	pending_threshold = i
	var unlocked: Array[StringName] = Profile.unlocked_options()
	pending_options = pool.draw(rng, taken, unlocked)
	Events.threshold_ready.emit(i, pending_options)

func _on_fade_fight() -> void:
	Events.fade_fight_started.emit()
	Multiverse.begin_fade_fight()

func _on_faded() -> void:
	if not active:
		return
	active = false
	var lines: PackedStringArray = Tuning.fade_lines.items
	var line: String = lines[rng.randi_range(0, lines.size() - 1)] if lines.size() > 0 else ""
	stats["result"] = "success" if clock.threat_ended else "faded"
	stats["fade_line"] = line
	Events.faded.emit(line)
	var s: Dictionary = summary()
	Profile.record_run(s)
	Profile.write_telemetry(telemetry())
	Events.run_finished.emit(s)

func _on_insight(d: InsightDef) -> void:
	build.set_source("insights", insights.effects_for_found())
	Profile.codex_add("insights", String(d.id))
	Events.insight_found.emit(d.id)

func end_threat() -> void:
	if clock.threat_ended:
		return
	stats["threat_result"] = "ended_fade_fight" if clock.phase == RunClock.Phase.FADE_FIGHT else "ended_early"
	stats["threat_time"] = clock.elapsed()
	Profile.codex_add("threats", "bloom")
	var early: bool = clock.phase != RunClock.Phase.FADE_FIGHT
	clock.end_threat()
	Events.threat_ended.emit(early)

## GDD §Telemetry (local only): time-to-first-chase, chases/min, time per dimension,
## threshold picks, clock lost to hits per minute, result.
func telemetry() -> Dictionary:
	var minutes: float = maxf(0.01, clock.elapsed() / 60.0)
	var ftc: int = int(stats.get("first_chase_tick", -1))
	var per_dim: Dictionary = {}
	for k: StringName in Multiverse.time_in:
		per_dim[String(k)] = snappedf(float(Multiverse.time_in[k]), 0.1)
	return {
		"seed": int(config.get("seed", 0)), "clock": clock.start,
		"time_to_first_chase_s": snappedf(ftc / 60.0, 0.01) if ftc >= 0 else -1.0,
		"chases_per_min": snappedf(float(stats.get("chases", 0)) / minutes, 0.01),
		"time_per_dimension_s": per_dim,
		"threshold_picks": taken.map(func(x: StringName) -> String: return String(x)),
		"clock_lost_to_hits_per_min": snappedf(clock.lost_to_hits / minutes, 0.01),
		"result": stats.get("result", ""),
	}

func summary() -> Dictionary:
	return {
		"seed": int(config.get("seed", 0)),
		"peak_power": snappedf(peak_power, 0.001),
		"result": stats.get("result", ""),
		"threat_result": stats.get("threat_result", ""),
		"threat_time": snappedf(float(stats.get("threat_time", -1.0)), 0.01),
		"marked": Multiverse.marked_list(),
		"longest_chain": int(stats.get("longest_chain", 0)),
		"insights": insights.found.duplicate(),
		"kills": int(stats.get("kills", 0)),
		"options": taken.duplicate(),
		"adaptations": adaptations.duplicate(),
		"lost_to_hits": snappedf(clock.lost_to_hits, 0.01),
		"ticks": tick,
		"fade_line": stats.get("fade_line", ""),
	}
