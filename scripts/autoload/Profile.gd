extends Node
## Persisted: Codex, unlocks, settings, best scores, run history (last 50).
## Atomic write (temp + rename); corrupt → backup, else fresh + toast.

const VERSION: int = 1

var data: Dictionary = {}
var path_override: String = ""
var persist: bool = true

func _ready() -> void:
	load_profile()

func path() -> String:
	return path_override if path_override != "" else Platform.profile_path()

func fresh() -> Dictionary:
	return {
		"version": VERSION,
		"first_run_done": false,
		"codex": {"insights": [], "options": [], "adaptations": [], "dimensions": [], "threats": []},
		"unlocks": [],
		"settings": default_settings(),
		"best": {"peak_power": 0.0, "longest_chain": 0},
		"history": [],
	}

func default_settings() -> Dictionary:
	return {
		"numeric_clock": false, "shake": 1.0, "flash": 1.0, "game_speed": 1.0,
		"guard_toggle": false, "beam_toggle": false, "subtitles": true,
		"master": 1.0, "music": 0.8, "sfx": 1.0, "voice": 1.0, "fullscreen": false,
		"bindings": {},
	}

func load_profile() -> void:
	data = fresh()
	var p: String = path()
	if not FileAccess.file_exists(p):
		return
	var parsed: Variant = _read_json(p)
	if parsed is Dictionary:
		data = migrate(parsed)
		return
	var bak: String = p.get_basename() + ".bak.json"
	var b: Variant = _read_json(bak)
	if b is Dictionary:
		data = migrate(b)
		Events.toast.emit("Codex restored from backup")
	else:
		Events.toast.emit("Codex unreadable — starting fresh")

func _read_json(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return null
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		return null
	return j.data

func migrate(d: Dictionary) -> Dictionary:
	var base: Dictionary = fresh()
	for k: String in base:
		if not d.has(k):
			d[k] = base[k]
	var s: Dictionary = d["settings"]
	for k: String in base["settings"]:
		if not s.has(k):
			s[k] = base["settings"][k]
	var c: Dictionary = d["codex"]
	for k: String in base["codex"]:
		if not c.has(k):
			c[k] = []
	d["version"] = VERSION
	return d

func save() -> bool:
	if not persist:
		return true
	var p: String = path()
	var tmp: String = p + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		Events.toast.emit("Codex not saved")
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var dir := DirAccess.open(p.get_base_dir())
	if dir == null:
		Events.toast.emit("Codex not saved")
		return false
	if FileAccess.file_exists(p):
		dir.copy(p, p.get_basename() + ".bak.json")
	if dir.rename(tmp, p) != OK:
		Events.toast.emit("Codex not saved")
		return false
	return true

func setting(key: String) -> Variant:
	return data["settings"].get(key, default_settings().get(key))

func set_setting(key: String, v: Variant) -> void:
	data["settings"][key] = v
	save()

func codex_add(section: String, id: String) -> void:
	var arr: Array = data["codex"][section]
	if not arr.has(id):
		arr.append(id)

func codex_has(section: String, id: String) -> bool:
	return (data["codex"][section] as Array).has(id)

func unlocked_options() -> Array[StringName]:
	var out: Array[StringName] = []
	for u: String in data["unlocks"]:
		out.append(StringName(u))
	return out

func record_run(summary: Dictionary) -> void:
	data["first_run_done"] = true
	var h: Array = data["history"]
	h.push_front(summary)
	while h.size() > 50:
		h.pop_back()
	var best: Dictionary = data["best"]
	best["peak_power"] = maxf(float(best["peak_power"]), float(summary.get("peak_power", 0.0)))
	best["longest_chain"] = maxi(int(best["longest_chain"]), int(summary.get("longest_chain", 0)))
	save()
