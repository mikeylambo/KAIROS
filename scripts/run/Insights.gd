class_name Insights
extends RefCounted
## Counts gameplay contexts; at def.count grants the insight's flag for the run.

signal discovered(def: InsightDef)

var defs: Array[InsightDef] = []
var counts: Dictionary = {}
var found: Array[StringName] = []

func load_all() -> void:
	defs.clear()
	for id: String in ["transmission_beam", "burst_launcher"]:
		var r: InsightDef = load("res://data/insights/%s.tres" % id)
		defs.append(r)
	counts.clear()
	found.clear()

func note(context: StringName) -> void:
	for d: InsightDef in defs:
		if d.context != context or found.has(d.id):
			continue
		var c: int = int(counts.get(d.id, 0)) + 1
		counts[d.id] = c
		if c >= d.count:
			found.append(d.id)
			discovered.emit(d)

func effects_for_found() -> Array[EffectDef]:
	var out: Array[EffectDef] = []
	for d: InsightDef in defs:
		if found.has(d.id):
			out.append(EffectDef.make("flag", d.grants_flag))
	return out
