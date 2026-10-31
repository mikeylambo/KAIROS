class_name BuildModifiers
extends RefCounted
## The single aggregator every system queries (BUILD_BRIEF §3). Sources are keyed
## so dimension rules can be swapped without touching permanent build effects.

var _sources: Dictionary = {}  # key(String) -> Array[EffectDef]

func set_source(key: String, effects: Array[EffectDef]) -> void:
	_sources[key] = effects

func clear_source(key: String) -> void:
	_sources.erase(key)

func has_source(key: String) -> bool:
	return _sources.has(key)

func source_keys() -> Array:
	return _sources.keys()

func mul(stat: StringName) -> float:
	var m: float = 1.0
	for k: String in _sources:
		for e: EffectDef in _sources[k]:
			if e.kind == "stat_mul" and e.stat == stat:
				m *= e.value
	return m

func add(stat: StringName) -> float:
	var a: float = 0.0
	for k: String in _sources:
		for e: EffectDef in _sources[k]:
			if e.kind == "stat_add" and e.stat == stat:
				a += e.value
	return a

func flag(stat: StringName) -> bool:
	for k: String in _sources:
		for e: EffectDef in _sources[k]:
			if e.kind == "flag" and e.stat == stat:
				return true
	return false

## Returns [spawn_id, count] pairs for an event.
func spawns_for(event: StringName) -> Array:
	var out: Array = []
	for k: String in _sources:
		for e: EffectDef in _sources[k]:
			if e.kind == "on_event_spawn" and e.event == event:
				out.append([e.spawn, int(e.value)])
	return out
