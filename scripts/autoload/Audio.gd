extends Node
## Buses (Master/Music/SFX/Voice), manifest-keyed streams with synthesized
## fallbacks, music cue + intensity layers, beam ducking, string pitch-rise.
## Presentation only: listens to Events, never touches gameplay.

const MUSIC_ROOTS: Dictionary = {
	&"music_title": [110.0, 0.2], &"music_threshold": [130.81, 0.7], &"music_leadfall": [98.0, 0.3],
	&"music_skyreach": [146.83, 0.8], &"music_corridor": [87.31, 0.1], &"music_overflow": [123.47, 0.9],
	&"music_fade_fight": [116.54, 0.4], &"music_bloom_lair": [103.83, 0.3],
}

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music_a: Array[AudioStreamPlayer] = []  # [pad, pulse]
var _music_b: Array[AudioStreamPlayer] = []
var _cue: StringName = &""
var _intensity: int = 1
var _fade_drums: float = 1.0
var _duck: float = 0.0
var _xfade: float = 1.0
var enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = not Platform.is_headless()
	for n: String in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")
	for i: int in 24:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	for arr: Array[AudioStreamPlayer] in [_music_a, _music_b]:
		for l: int in 2:
			var p := AudioStreamPlayer.new()
			p.bus = "Music"
			p.volume_db = -80.0
			add_child(p)
			arr.append(p)
	Events.hit_landed.connect(func(_p: Vector2, kind: StringName, _d: float, chain: int) -> void:
		var pitch: float = 1.0 + minf(0.6, float(chain % 12) * 0.05)
		play(&"hit_heavy" if kind == &"heavy" or kind == &"collide" else &"hit_light", pitch))
	Events.launched.connect(func(_p: Vector2, _d: Vector2) -> void: play(&"hit_heavy", 0.8))
	Events.transmitted.connect(func(_a: Vector2, _b: Vector2, _c: bool) -> void: play(&"transmit"))
	Events.perfect_guard.connect(func(_p: Vector2) -> void: play(&"perfect"))
	Events.zenith_hit.connect(func(_p: Vector2, _c: float) -> void: play(&"time_loss", 1.0, 2.0))
	Events.burst.connect(func(_p: Vector2, _d: Vector2) -> void: play(&"burst"))
	Events.field_fired.connect(func(_p: Vector2, _r: float) -> void: play(&"field"))
	Events.volley_fired.connect(func(_p: Vector2) -> void: play(&"whiff", 1.8, -6.0))
	Events.whiff.connect(func(_p: Vector2) -> void: play(&"whiff"))
	Events.jumped.connect(func(_p: Vector2) -> void: play(&"jump", 1.0, -8.0))
	Events.beam_started.connect(func(_p: Vector2) -> void:
		play(&"beam_fire")
		_duck = 1.0)
	Events.beam_ended.connect(func(_p: Vector2, fin: bool) -> void:
		_duck = 0.0
		if fin:
			play(&"beam_end"))
	Events.world_break.connect(func(_p: Vector2) -> void: play(&"crack"))
	Events.terrain_impact.connect(func(_p: Vector2) -> void: play(&"hit_heavy", 0.6, -6.0))
	Events.threshold_ready.connect(func(_i: int, _o: Array) -> void:
		play(&"threshold")
		_intensity = mini(2, _intensity + 1))
	Events.dimension_entered.connect(func(id: StringName) -> void: cue_for_dimension(id))
	Events.overflow_started.connect(func() -> void: music(&"music_overflow"))
	Events.fade_fight_started.connect(func() -> void: music(&"music_fade_fight"))
	Events.bloom_phase.connect(func(_n: int) -> void: play(&"bloom_roar", 1.0, -2.0))
	Events.faded.connect(func(_l: String) -> void:
		music(&"")
		play(&"note", 1.0, -4.0))
	apply_volumes()

func apply_volumes() -> void:
	for pair: Array in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"], ["Voice", "voice"]]:
		var i: int = AudioServer.get_bus_index(pair[0])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(0.0001, float(Profile.setting(pair[1])))))

func stream(key: StringName) -> AudioStream:
	if _cache.has(key):
		return _cache[key]
	var path: String = Tuning.audio.resolve(key) if Tuning.audio else ""
	var s: AudioStream
	if path != "":
		s = load(path)
	elif MUSIC_ROOTS.has(key):
		s = null
	else:
		s = Synth.sfx(key)
	_cache[key] = s
	return s

func play(key: StringName, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not enabled:
		return
	var s: AudioStream = stream(key)
	if s == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()

func cue_for_dimension(id: StringName) -> void:
	if Run.clock.overflow:
		return
	if Multiverse.fade_fight:
		music(&"music_fade_fight")
		return
	music(StringName("music_" + String(id)))

func _music_stream(key: StringName, layer: int) -> AudioStream:
	var ck: StringName = StringName("%s#%d" % [key, layer])
	if _cache.has(ck):
		return _cache[ck]
	var path: String = Tuning.audio.resolve(key) if layer == 0 else ""
	var s: AudioStream
	if path != "":
		s = load(path)
	else:
		var r: Array = MUSIC_ROOTS.get(key, [110.0, 0.5])
		s = Synth.music(float(r[0]), layer, float(r[1]))
	_cache[ck] = s
	return s

func music(key: StringName) -> void:
	if key == _cue or not enabled:
		return
	_cue = key
	var tmp: Array[AudioStreamPlayer] = _music_a
	_music_a = _music_b
	_music_b = tmp
	_xfade = 0.0
	for l: int in 2:
		var p: AudioStreamPlayer = _music_a[l]
		if key == &"":
			p.stop()
			continue
		p.stream = _music_stream(key, l)
		p.volume_db = -80.0
		p.play()

func set_fade_progress(k: float) -> void:
	_fade_drums = clampf(1.0 - k, 0.0, 1.0)

func _process(delta: float) -> void:
	if not enabled:
		return
	_xfade = minf(1.0, _xfade + delta / 1.5)
	if Run.sim and Run.active:
		_intensity = 2 if Run.sim.live_enemies() >= 6 or Run.clock.overflow else 1
	var duck_db: float = -6.0 * _duck
	var pad_db: float = linear_to_db(maxf(0.0001, _xfade)) + duck_db
	var pulse_lin: float = _xfade * (1.0 if _intensity >= 2 else 0.0) * _fade_drums
	_music_a[0].volume_db = pad_db
	_music_a[1].volume_db = linear_to_db(maxf(0.0001, pulse_lin)) + duck_db
	for p: AudioStreamPlayer in _music_b:
		p.volume_db = linear_to_db(maxf(0.0001, 1.0 - _xfade)) + duck_db
		if _xfade >= 1.0 and p.playing:
			p.stop()
