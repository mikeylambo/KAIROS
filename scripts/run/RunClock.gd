class_name RunClock
extends RefCounted
## The life clock. Owns remaining time, phase, thresholds, overflow, fade.
## Invariant: `remaining` never increases.

enum Phase { LIVING, FADE_FIGHT, FREE, FADED }

signal threshold_reached(index: int)
signal overflow_started()
signal fade_fight_started()
signal faded()
signal time_lost(seconds: float)

var start: float = 1800.0
var remaining: float = 1800.0
var phase: Phase = Phase.LIVING
var marks: PackedFloat32Array = PackedFloat32Array()
var next_threshold: int = 0
var overflow_at: float = 1680.0
var overflow: bool = false
var fade_len: float = 60.0
var fade_left: float = 60.0
var threat_ended: bool = false
var lost_to_hits: float = 0.0

func setup(t: KairosTuning, start_seconds: float) -> void:
	start = start_seconds
	remaining = start_seconds
	var s: float = start_seconds / t.clock_start
	marks = PackedFloat32Array()
	for m: float in t.threshold_marks:
		marks.append(m * s)
	overflow_at = t.overflow_at * s
	fade_len = maxf(10.0, t.fade_fight_len * minf(1.0, s * 4.0))
	fade_left = fade_len
	phase = Phase.LIVING
	next_threshold = 0
	overflow = false
	threat_ended = false
	lost_to_hits = 0.0

func elapsed() -> float:
	return start - remaining

## Scaled time used by the power curve (so short presets traverse the full curve).
func life_fraction() -> float:
	return clampf(elapsed() / start, 0.0, 1.0)

func tick(dt: float) -> void:
	if dt <= 0.0:
		return
	match phase:
		Phase.LIVING, Phase.FREE:
			_drain(dt)
		Phase.FADE_FIGHT:
			fade_left = maxf(0.0, fade_left - dt)
			if fade_left <= 0.0:
				phase = Phase.FADED
				faded.emit()

func cost(seconds: float) -> void:
	if seconds <= 0.0 or phase == Phase.FADED:
		return
	if phase == Phase.FADE_FIGHT:
		var before_f: float = fade_left
		fade_left = maxf(0.0, fade_left - seconds)
		time_lost.emit(before_f - fade_left)
		if fade_left <= 0.0:
			phase = Phase.FADED
			faded.emit()
		return
	var before: float = remaining
	_drain(seconds)
	lost_to_hits += before - remaining
	time_lost.emit(before - remaining)

func end_threat() -> void:
	threat_ended = true
	if phase == Phase.LIVING:
		phase = Phase.FREE
	elif phase == Phase.FADE_FIGHT:
		phase = Phase.FADED
		faded.emit()

func _drain(dt: float) -> void:
	remaining = maxf(0.0, remaining - dt)
	var e: float = elapsed()
	while next_threshold < marks.size() and e >= marks[next_threshold]:
		var i: int = next_threshold
		next_threshold += 1
		threshold_reached.emit(i)
	if not overflow and e >= overflow_at:
		overflow = true
		overflow_started.emit()
	if remaining <= 0.0:
		if threat_ended:
			phase = Phase.FADED
			faded.emit()
		else:
			phase = Phase.FADE_FIGHT
			fade_left = fade_len
			fade_fight_started.emit()
