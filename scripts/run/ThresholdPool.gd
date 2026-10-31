class_name ThresholdPool
extends RefCounted
## Loads every ThresholdOptionDef in data/ and draws 3 distinct, untaken options.

var all: Array[ThresholdOptionDef] = []

func load_all() -> void:
	all.clear()
	for id: String in ["resonant_beam", "omni_burst_field", "martial_fluency", "phantom_echo",
			"vessel_expansion", "split_beam", "chase_mastery"]:
		var r: ThresholdOptionDef = load("res://data/threshold_options/%s.tres" % id)
		all.append(r)

func get_def(id: StringName) -> ThresholdOptionDef:
	for o: ThresholdOptionDef in all:
		if o.id == id:
			return o
	return null

func draw(rng: RandomNumberGenerator, taken: Array[StringName], unlocked: Array[StringName]) -> Array[ThresholdOptionDef]:
	var cand: Array[ThresholdOptionDef] = []
	for o: ThresholdOptionDef in all:
		if taken.has(o.id):
			continue
		if not o.unlocked_by_default and not unlocked.has(o.id):
			continue
		cand.append(o)
	var out: Array[ThresholdOptionDef] = []
	while out.size() < 3 and cand.size() > 0:
		var i: int = rng.randi_range(0, cand.size() - 1)
		out.append(cand[i])
		cand.remove_at(i)
	return out
