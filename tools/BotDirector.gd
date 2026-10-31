class_name BotDirector
extends RefCounted
## Scenario layer over BotBrain: decides where to go (warps via Run.command, so
## the InputLog records them) and picks threshold options.

var brain := BotBrain.new()
var scenario: String = "win"
var log_lines: PackedStringArray = PackedStringArray()
var thresholds: Array = []
var last_remaining: float = INF
var clock_increased: bool = false
var visited: Array[StringName] = []
var prev_elapsed: float = 0.0

func _init(sc: String) -> void:
	scenario = sc
	brain.mode = "idle" if sc == "fade" else "fight"
	Events.threshold_ready.connect(func(i: int, _o: Array) -> void: thresholds.append([i, prev_elapsed, Run.clock.elapsed()]))

func note(s: String) -> void:
	log_lines.append("[%6.2f] %s" % [Run.clock.elapsed(), s])

func next_input(sim: Sim) -> int:
	if Run.clock.remaining > last_remaining + 0.0001:
		clock_increased = true
	last_remaining = Run.clock.remaining
	prev_elapsed = Run.clock.elapsed()
	if Run.pending_threshold >= 0 and Run.pending_options.size() > 0:
		var pick: ThresholdOptionDef = Run.pending_options[0]
		for o: ThresholdOptionDef in Run.pending_options:
			if o.id == &"chase_mastery" or o.id == &"martial_fluency":
				pick = o
		note("threshold %d → %s" % [Run.pending_threshold, pick.id])
		Run.choose_option(pick.id)
		return InputLog.pack(0, Vector2.ZERO)
	if not visited.has(Multiverse.current):
		visited.append(Multiverse.current)
		note("in " + String(Multiverse.current))
	var e: float = Run.clock.elapsed()
	match scenario:
		"win":
			if Multiverse.current == &"threshold" and e > 12.0:
				_warp(&"leadfall")
			elif Multiverse.current == &"leadfall" and Run.adaptations.has(&"weight"):
				_warp(&"skyreach")
		"early":
			if Multiverse.lair_visible and Multiverse.current != &"bloom_lair" and not Run.clock.threat_ended:
				_warp(&"bloom_lair")
			elif Run.clock.threat_ended and Multiverse.current == &"bloom_lair":
				_warp(&"skyreach")
	return brain.next_input(sim)

func _warp(id: StringName) -> void:
	note("warp → " + String(id))
	Run.command("warp", String(id))
