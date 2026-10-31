extends Node
## Owns: current dimension, exposure, marks, consumed nodes, The Bloom's map state,
## corridor travel.

const IDS: Array[StringName] = [&"threshold", &"leadfall", &"skyreach", &"corridor", &"bloom_lair"]
const SPREAD_ORDER: Array[StringName] = [&"threshold", &"leadfall", &"skyreach"]

var dims: Dictionary = {}
var current: StringName = &"threshold"
var exposure: Dictionary = {}
var marked: Dictionary = {}
var consumed: Dictionary = {}
var lair_visible: bool = false
var spread_count: int = 0
var corridor_dest: StringName = &""
var visits: Dictionary = {}
var fade_fight: bool = false
## Bumped on every dimension change so the Sim rebuilds the world.
var generation: int = 0

func _ready() -> void:
	for id: StringName in IDS:
		dims[id] = load("res://data/dimensions/%s.tres" % id)

func setup() -> void:
	current = &"threshold"
	exposure.clear()
	marked.clear()
	consumed.clear()
	visits.clear()
	lair_visible = false
	spread_count = 0
	corridor_dest = &""
	fade_fight = false
	generation += 1
	_apply_rules()

func def(id: StringName = &"") -> DimensionDef:
	return dims.get(current if id == &"" else id)

func is_consumed(id: StringName) -> bool:
	return consumed.has(id)

func band_of(id: StringName) -> int:
	var d: DimensionDef = def(id)
	return d.band + (1 if is_consumed(id) else 0)

func marked_list() -> Array:
	var out: Array = []
	for k: StringName in marked:
		out.append(String(k))
	return out

func destinations() -> Array[StringName]:
	var out: Array[StringName] = [&"threshold", &"leadfall", &"skyreach"]
	if lair_visible:
		out.append(&"bloom_lair")
	return out

func warp(id: StringName) -> void:
	if id == current or not dims.has(id) or id == &"corridor":
		return
	Run.clock.cost(Tuning.t.cost_warp)
	_enter(id)

func travel_corridor(dest: StringName) -> void:
	if dest == current or not dims.has(dest):
		return
	corridor_dest = dest
	_enter(&"corridor")

func arrive_from_corridor() -> void:
	if corridor_dest == &"":
		return
	var d: StringName = corridor_dest
	corridor_dest = &""
	_enter(d)

func begin_fade_fight() -> void:
	fade_fight = true
	if current != &"bloom_lair":
		_enter(&"bloom_lair")
	else:
		generation += 1

func _enter(id: StringName) -> void:
	current = id
	visits[id] = int(visits.get(id, 0)) + 1
	generation += 1
	_apply_rules()
	Profile.codex_add("dimensions", String(id))
	Events.dimension_entered.emit(id)
	_check_mark()

func _apply_rules() -> void:
	var d: DimensionDef = def()
	Run.build.set_source("dimension", d.rules)

func _check_mark() -> void:
	for a: StringName in Run.adaptations:
		var ad: AdaptationDef = Tuning.adaptation(a)
		if ad.marks_dimension == current and not marked.has(current):
			marked[current] = a
			Events.dimension_marked.emit(current)

func add_exposure(amount: float) -> void:
	var d: DimensionDef = def()
	if d.adaptation_id == &"" or Run.adaptations.has(d.adaptation_id):
		return
	var v: float = minf(Tuning.prog.exposure_full, float(exposure.get(current, 0.0)) + amount)
	exposure[current] = v
	Events.exposure_changed.emit(current, v)
	if v >= Tuning.prog.exposure_full:
		Run.grant_adaptation(d.adaptation_id)

func exposure_of(id: StringName) -> float:
	return float(exposure.get(id, 0.0))

## Called each sim tick with scaled elapsed seconds.
func tick_threat(elapsed: float) -> void:
	if Run.clock.threat_ended:
		return
	var s: float = Run.clock.start / Tuning.t.clock_start
	if not lair_visible and elapsed >= Tuning.threat.lair_time * s:
		lair_visible = true
		Events.lair_revealed.emit()
	var due: int = int(floor(elapsed / (Tuning.threat.spread_interval * s)))
	while spread_count < due and spread_count < SPREAD_ORDER.size():
		var target: StringName = SPREAD_ORDER[(spread_count + 1) % SPREAD_ORDER.size()]
		consumed[target] = true
		spread_count += 1
		Events.node_consumed.emit(target)
