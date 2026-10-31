extends Node
## Loads every project script; any parse/compile error fails the check.

func run() -> int:
	var bad: int = 0
	for p: String in _scan("res://"):
		var s: Resource = load(p)
		if s == null or (s is GDScript and not (s as GDScript).can_instantiate()):
			push_error("parse failed: " + p)
			bad += 1
	print("parse_all: %d bad" % bad)
	return 1 if bad > 0 else 0

func _scan(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		if sub.begins_with(".") or sub == "addons" or sub == "build":
			continue
		out.append_array(_scan(dir.path_join(sub)))
	return out
