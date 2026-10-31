extends SceneTree
## Regenerates every content table in data/ from one readable source.
## Run: godot --headless -s tools/gen_data.gd

func _e(k: String, s: StringName, v: float = 1.0, ev: StringName = &"", sp: StringName = &"") -> EffectDef:
	return EffectDef.make(k, s, v, ev, sp)

func _save(r: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(r, path)
	if err != OK:
		push_error("save failed %s" % path)

func _init() -> void:
	_save(KairosTuning.new(), "res://data/tuning.tres")
	_save(ProgressionDef.new(), "res://data/progression.tres")
	_save(ThreatDef.new(), "res://data/threats/bloom.tres")
	_dimensions()
	_adaptations()
	_options()
	_insights()
	_enemies()
	_misc()
	print("gen_data: ok")
	quit()

func _dim(id: StringName, nm: String, band: int, grounded: bool, w: int, h: int, pal: Array, enemies: Array, pos: Vector2) -> DimensionDef:
	var d := DimensionDef.new()
	d.id = id
	d.display_name = nm
	d.band = band
	d.grounded = grounded
	d.chunks_wide = w
	d.chunks_tall = h
	d.palette = PackedColorArray(pal)
	d.enemy_table = PackedStringArray(enemies)
	d.chunk_pool = id
	d.music_key = StringName("music_" + String(id))
	d.map_pos = pos
	return d

func _dimensions() -> void:
	var th := _dim(&"threshold", "The Threshold", 1, true, 6, 1,
		[Color("#1b2233"), Color("#2c3550"), Color("#56607c"), Color("#9aa3b8"), Color("#c9cfdc")],
		["drone", "drone", "drone", "brute"], Vector2(0.18, 0.55))
	th.rule_text = "—"
	_save(th, "res://data/dimensions/threshold.tres")
	var lf := _dim(&"leadfall", "Leadfall", 2, true, 6, 1,
		[Color("#1d1a1a"), Color("#3a3230"), Color("#5e5450"), Color("#8b817a"), Color("#b5aaa0")],
		["slammer", "gunner", "gunner"], Vector2(0.52, 0.30))
	lf.rules = [_e("stat_mul", &"gravity", 2.0)]
	lf.rule_text = "Gravity ×2"
	lf.adaptation_id = &"weight"
	_save(lf, "res://data/dimensions/leadfall.tres")
	var sr := _dim(&"skyreach", "Skyreach", 2, false, 6, 3,
		[Color("#162436"), Color("#24425e"), Color("#4b7aa0"), Color("#9cc4dc"), Color("#e2f0f6")],
		["flyer", "flyer", "lancer"], Vector2(0.55, 0.78))
	sr.rules = [_e("flag", &"no_ground"), _e("flag", &"enemies_fly")]
	sr.rule_text = "No ground"
	sr.adaptation_id = &"lift"
	_save(sr, "res://data/dimensions/skyreach.tres")
	var co := _dim(&"corridor", "The Corridor", 0, false, 1, 1,
		[Color("#05050b"), Color("#0d0b1e"), Color("#1d1840"), Color("#4a3f8a"), Color("#c8c0ff")],
		[], Vector2(0.36, 0.55))
	co.is_corridor = true
	co.enemy_target = 0
	co.rule_text = "Free passage"
	_save(co, "res://data/dimensions/corridor.tres")
	var la := _dim(&"bloom_lair", "The Bloom's Lair", 2, true, 1, 1,
		[Color("#140812"), Color("#2a0f26"), Color("#4d1a45"), Color("#8a2f7a"), Color("#ffd1f2")],
		[], Vector2(0.86, 0.50))
	la.enemy_target = 0
	la.rule_text = "The threat"
	_save(la, "res://data/dimensions/bloom_lair.tres")

func _adaptations() -> void:
	var w := AdaptationDef.new()
	w.id = &"weight"
	w.display_name = "Weight"
	w.glyph = "▼"
	w.description = "Hits pin for 60f and crush ×1.55. Flight speed ×0.7."
	w.effects = [_e("stat_add", &"pin_f", 60.0), _e("stat_mul", &"crush", 1.55), _e("stat_mul", &"fly_speed", 0.7)]
	w.marks_dimension = &"skyreach"
	_save(w, "res://data/adaptations/weight.tres")
	var l := AdaptationDef.new()
	l.id = &"lift"
	l.display_name = "Lift"
	l.glyph = "▲"
	l.description = "Full-speed hover combat. Knockback taken ×1.45."
	l.effects = [_e("flag", &"hover_combat"), _e("stat_mul", &"knockback_taken", 1.45)]
	_save(l, "res://data/adaptations/lift.tres")

func _opt(id: StringName, nm: String, cat: String, desc: String, fx: Array[EffectDef]) -> void:
	var o := ThresholdOptionDef.new()
	o.id = id
	o.display_name = nm
	o.category = cat
	o.description = desc
	o.effects = fx
	_save(o, "res://data/threshold_options/%s.tres" % id)

func _options() -> void:
	_opt(&"resonant_beam", "Resonant Beam", "technique", "Beam charge 40% faster, +50% width.",
		[_e("stat_mul", &"beam_charge_rate", 1.4), _e("stat_mul", &"beam_width", 1.5)])
	_opt(&"omni_burst_field", "Omni-Burst Field", "technique", "Field radius +60%, reflects bolts.",
		[_e("stat_mul", &"field_radius", 1.6), _e("flag", &"field_reflect")])
	_opt(&"martial_fluency", "Martial Fluency", "passive", "+50% ki on hit. Transmit recovery 0f.",
		[_e("stat_mul", &"ki_gain", 1.5), _e("stat_mul", &"transmit_recovery", 0.0)])
	_opt(&"phantom_echo", "Phantom Echo", "passive", "Perfect guard leaves 2 detonating afterimages.",
		[_e("on_event_spawn", &"echo", 2.0, &"perfect_guard", &"echo_mine")])
	_opt(&"vessel_expansion", "Vessel Expansion", "ki", "Max ki 150.",
		[_e("stat_add", &"ki_max", 50.0)])
	_opt(&"split_beam", "Split Beam", "technique", "Beam splits into 3 on impact.",
		[_e("flag", &"beam_split")])
	_opt(&"chase_mastery", "Chase Mastery", "passive", "Chase window +40f; chase arrival deals 40.",
		[_e("stat_add", &"chase_window_f", 40.0), _e("stat_add", &"chase_arrival_dmg", 40.0)])

func _insights() -> void:
	var a := InsightDef.new()
	a.id = &"transmission_beam"
	a.display_name = "Transmission Beam"
	a.description = "Fire the beam straight out of a transmit."
	a.context = &"beam_after_transmit"
	a.grants_flag = &"transmission_beam"
	_save(a, "res://data/insights/transmission_beam.tres")
	var b := InsightDef.new()
	b.id = &"burst_launcher"
	b.display_name = "Burst Launcher"
	b.description = "Launch out of a burst without losing speed."
	b.context = &"heavy_while_bursting"
	b.grants_flag = &"burst_launcher"
	_save(b, "res://data/insights/burst_launcher.tres")

func _en(id: StringName, nm: String, beh: StringName, hp: float, armor: int, flies: bool, size: Vector2, spd: float, wind: int, rng: float, heavy: bool, xp: float, col: Color) -> void:
	var e := EnemyDef.new()
	e.id = id
	e.display_name = nm
	e.behavior = beh
	e.hp = hp
	e.armor = armor
	e.flies = flies
	e.size = size
	e.speed = spd
	e.windup_f = wind
	e.attack_range = rng
	e.heavy_attack = heavy
	e.xp = xp
	e.color = col
	_save(e, "res://data/enemies/%s.tres" % id)

func _enemies() -> void:
	_en(&"drone", "Crisis Drone", &"drone", 60, 0, true, Vector2(1.2, 1.0), 9.0, 30, 7.0, false, 10, Color("#8d97ad"))
	_en(&"brute", "Brute", &"brute", 220, 0, false, Vector2(2.0, 2.6), 6.0, 40, 4.5, true, 30, Color("#6d7690"))
	_en(&"slammer", "Slammer", &"slammer", 320, 3, false, Vector2(2.2, 2.4), 7.0, 36, 10.0, true, 45, Color("#7a6d66"))
	_en(&"gunner", "Gunner", &"gunner", 140, 0, false, Vector2(1.4, 2.0), 7.0, 34, 22.0, true, 30, Color("#8f8178"))
	_en(&"flyer", "Skyreach Flyer", &"flyer", 90, 0, true, Vector2(1.4, 1.0), 14.0, 26, 8.0, false, 18, Color("#9cc4dc"))
	_en(&"lancer", "Lancer", &"lancer", 180, 0, true, Vector2(2.4, 1.2), 10.0, 44, 30.0, true, 32, Color("#7aa6c4"))
	_en(&"bloom_spore", "Spore", &"spore", 30, 0, true, Vector2(0.8, 0.8), 6.0, 20, 4.0, false, 3, Color("#d94fb8"))

func _misc() -> void:
	var fl := StringList.new()
	fl.items = PackedStringArray([
		"Thirty minutes. I spent every one.",
		"Brighter than the world could hold. That was enough.",
		"Nothing could touch me. Only this.",
		"I was never meant to stay. Only to burn.",
		"Remember the light, not the length.",
	])
	_save(fl, "res://data/fade_lines.tres")
	var set := FxRecipeSet.new()
	var cy := Color("#3FF6FF")
	var mg := Color("#FF3FD8")
	set.recipes = [
		_fx(&"spark_s", &"spark", 6, 0.18, Vector2(6, 14), Vector2(2, 4), [Color.WHITE, cy], 2.0, 0.0, &"hit_light"),
		_fx(&"spark_m", &"spark", 10, 0.24, Vector2(8, 20), Vector2(3, 6), [Color.WHITE, cy, mg], 4.0, 0.0, &"hit_light"),
		_fx(&"spark_l", &"spark", 18, 0.32, Vector2(12, 30), Vector2(4, 9), [Color.WHITE, mg, cy], 6.0, 1.0, &"hit_heavy"),
		_fx(&"transmit_ring", &"ring", 1, 0.30, Vector2(0, 0), Vector2(1, 4), [cy], 0.0, 0.0, &"transmit"),
		_fx(&"field_wave", &"ring", 1, 0.35, Vector2(0, 0), Vector2(1, 10), [Color.WHITE, mg], 5.0, 0.6, &"field"),
		_fx(&"beam_impact", &"spark", 24, 0.4, Vector2(10, 34), Vector2(4, 10), [Color.WHITE, cy, mg], 8.0, 1.0, &"beam_end"),
		_fx(&"guard_chime", &"ring", 1, 0.25, Vector2(0, 0), Vector2(1, 3), [Color.WHITE], 0.0, 0.3, &"perfect"),
		_fx(&"time_shard", &"spark", 8, 0.3, Vector2(4, 10), Vector2(2, 5), [Color("#FF8A1F"), Color.WHITE], 3.0, 0.0, &"time_loss"),
		_fx(&"dust", &"spark", 10, 0.4, Vector2(2, 8), Vector2(3, 8), [Color("#b5aaa0")], 3.0, 0.0, &""),
		_fx(&"feathers", &"spark", 8, 0.6, Vector2(2, 6), Vector2(2, 5), [Color("#e2f0f6"), cy], 0.0, 0.0, &""),
		_fx(&"bloom_burst", &"spark", 16, 0.5, Vector2(6, 18), Vector2(3, 8), [mg, Color("#ffd1f2")], 4.0, 0.0, &"hit_heavy"),
	]
	_save(set, "res://data/fx_recipes.tres")
	var am := AssetManifest.new()
	for k: String in ["zenith", "drone", "brute", "slammer", "gunner", "flyer", "lancer", "bloom"]:
		am.entries["sprite_" + k] = "res://assets/sprites/%s/%s.tres" % [k, k]
	for d: String in ["threshold", "leadfall", "skyreach", "corridor"]:
		for i: int in 5:
			am.entries["bg_%s_%d" % [d, i]] = "res://assets/backgrounds/%s/layer_%d.png" % [d, i]
	_save(am, "res://data/asset_manifest.tres")
	var au := AssetManifest.new()
	for k: String in ["hit_light", "hit_heavy", "transmit", "beam_charge", "beam_fire", "beam_end", "time_loss", "threshold", "perfect", "burst", "field", "whiff", "ui_move", "ui_select", "jump", "crack", "bloom_roar"]:
		au.entries[k] = "res://assets/audio/sfx/%s.ogg" % k
	au.entries["voice_zenith_line"] = "res://assets/audio/voice/voice_zenith_line.mp3"
	for k: String in ["music_threshold", "music_leadfall", "music_skyreach", "music_corridor", "music_overflow", "music_fade_fight", "music_title"]:
		au.entries[k] = "res://assets/audio/music/%s.ogg" % k
	_save(au, "res://data/audio_manifest.tres")

func _fx(id: StringName, fam: StringName, n: int, life: float, spd: Vector2, sz: Vector2, cols: Array, shake: float, flash: float, sfx: StringName) -> FxRecipe:
	var r := FxRecipe.new()
	r.id = id
	r.family = fam
	r.count = n
	r.lifetime = life
	r.speed = spd
	r.size = sz
	r.colors = PackedColorArray(cols)
	r.shake_px = shake
	r.flash = flash
	r.sfx = sfx
	return r
