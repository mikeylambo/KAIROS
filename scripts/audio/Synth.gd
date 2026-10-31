class_name Synth
extends RefCounted
## Deterministic placeholder synthesis → AudioStreamWAV (16-bit mono).

const RATE: int = 22050

static func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b

static func sfx(key: StringName) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	match key:
		&"hit_light": return _hit(rng, 190.0, 0.09, 0.5)
		&"hit_heavy": return _hit(rng, 62.0, 0.28, 0.8)
		&"transmit": return _sweep(rng, 0.18, 2400.0, 300.0, 0.6, true)
		&"beam_charge": return _tone_sweep(1.5, 180.0, 900.0, 0.35)
		&"beam_fire": return _roar(rng, 1.2)
		&"beam_end": return _glass(rng, 0.9, 0.8)
		&"time_loss": return _shard(0.32)
		&"threshold": return _choir(2.2)
		&"perfect": return _bells([1760.0, 2637.0, 3520.0], 0.6, 0.5)
		&"burst": return _sweep(rng, 0.15, 900.0, 3200.0, 0.4, false)
		&"field": return _hit(rng, 48.0, 0.45, 0.7)
		&"whiff": return _sweep(rng, 0.12, 600.0, 1800.0, 0.22, false)
		&"ui_move": return _bells([1200.0], 0.05, 0.25)
		&"ui_select": return _bells([880.0, 1320.0], 0.18, 0.35)
		&"jump": return _sweep(rng, 0.1, 300.0, 900.0, 0.18, false)
		&"crack": return _glass(rng, 0.25, 0.5)
		&"bloom_roar": return _roar(rng, 1.6)
		&"note": return _bells([220.0, 330.0], 6.0, 0.3)
	return _bells([660.0], 0.1, 0.3)

static func _hit(rng: RandomNumberGenerator, f0: float, dur: float, amp: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var ph: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / RATE
		var env: float = exp(-t * 6.0 / dur)
		var f: float = f0 * (1.0 + 2.0 * exp(-t * 40.0))
		ph += TAU * f / RATE
		var n: float = rng.randf_range(-1.0, 1.0) * exp(-t * 60.0)
		b[i] = (sin(ph) * 0.8 + n * 0.6) * env * amp
	return _wav(b)

static func _sweep(rng: RandomNumberGenerator, dur: float, f_a: float, f_b: float, amp: float, crack: bool) -> AudioStreamWAV:
	var b := _buf(dur)
	var lp: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / RATE
		var k: float = t / dur
		var cutoff: float = lerpf(f_a, f_b, k) / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * clampf(cutoff * 6.0, 0.01, 1.0)
		var env: float = sin(PI * k)
		b[i] = lp * env * amp * 2.0
		if crack and k > 0.85:
			b[i] += rng.randf_range(-1.0, 1.0) * (1.0 - k) * 4.0 * amp
	return _wav(b)

static func _tone_sweep(dur: float, f_a: float, f_b: float, amp: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var ph: float = 0.0
	for i: int in b.size():
		var k: float = float(i) / b.size()
		ph += TAU * lerpf(f_a, f_b, k * k) / RATE
		b[i] = (sin(ph) + 0.3 * sin(ph * 2.01)) * amp * minf(1.0, k * 8.0)
	return _wav(b)

static func _roar(rng: RandomNumberGenerator, dur: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var lp: float = 0.0
	var ph: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.08
		ph += TAU * 82.0 / RATE
		var saw: float = fposmod(ph / TAU, 1.0) * 2.0 - 1.0
		var env: float = minf(1.0, t * 20.0) * minf(1.0, (dur - t) * 6.0)
		b[i] = (lp * 1.4 + saw * 0.25) * env * 0.6
	return _wav(b)

static func _glass(rng: RandomNumberGenerator, dur: float, amp: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var parts: Array[float] = [2093.0, 3136.0, 4186.0, 5274.0]
	for i: int in b.size():
		var t: float = float(i) / RATE
		var s: float = 0.0
		for p: float in parts:
			s += sin(TAU * p * t) * exp(-t * (4.0 + p / 1000.0))
		s = s * 0.25 + rng.randf_range(-1.0, 1.0) * exp(-t * 25.0) * 0.8
		b[i] = s * amp
	return _wav(b)

static func _shard(dur: float) -> AudioStreamWAV:
	var b := _buf(dur)
	for i: int in b.size():
		var t: float = float(i) / RATE
		var rev: float = dur - t
		var s: float = sin(TAU * 1568.0 * t) * 0.5 + sin(TAU * 2349.0 * t) * 0.35 + sin(TAU * 3951.0 * t) * 0.2
		b[i] = s * exp(-rev * 9.0) * 0.6
	return _wav(b)

static func _choir(dur: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var chord: Array[float] = [220.0, 277.18, 329.63, 440.0, 554.37]
	for i: int in b.size():
		var t: float = float(i) / RATE
		var s: float = 0.0
		for f: float in chord:
			s += sin(TAU * f * t + sin(t * 5.0) * 0.4) + sin(TAU * f * 1.003 * t) * 0.6
		var env: float = minf(1.0, t / 0.8) * minf(1.0, (dur - t) / 0.6)
		var bell: float = sin(TAU * 880.0 * t) * exp(-t * 2.5) * 0.6
		b[i] = (s * 0.07 * env + bell) * 0.8
	return _wav(b)

static func _bells(fs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var b := _buf(dur)
	for i: int in b.size():
		var t: float = float(i) / RATE
		var s: float = 0.0
		for f: float in fs:
			s += sin(TAU * float(f) * t)
		b[i] = s / fs.size() * exp(-t * 5.0 / maxf(dur, 0.05)) * amp * minf(1.0, t * 400.0)
	return _wav(b)

## Music stem: root (Hz), layer 0 = pads, 1 = pulse/drums. 8 s loop.
static func music(root: float, layer: int, mood: float) -> AudioStreamWAV:
	var dur: float = 8.0
	var b := _buf(dur)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(root * 10.0) + layer
	var prog: Array[float] = [1.0, 1.2, 0.889, 1.0]
	if mood <= 0.5:
		prog = [1.0, 0.8, 0.75, 0.889]
	var lp: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / RATE
		var bar: int = int(t / 2.0) % 4
		var f: float = root * prog[bar]
		if layer == 0:
			var s: float = sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.5 * t) + 0.35 * sin(TAU * f * 2.0 * t + sin(t))
			b[i] = s * 0.12 * (0.8 + 0.2 * sin(TAU * t / 8.0))
		else:
			var beat: float = fposmod(t, 0.5)
			var kick: float = sin(TAU * 55.0 * beat * (1.0 + 3.0 * exp(-beat * 30.0))) * exp(-beat * 14.0)
			var hb: float = fposmod(t + 0.25, 0.5)
			lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.6
			var hat: float = lp * exp(-hb * 60.0) * 0.3
			var arp: float = sin(TAU * f * 4.0 * t) * exp(-fposmod(t, 0.125) * 30.0) * 0.12
			b[i] = (kick * 0.55 + hat + arp) * 0.7
	return _wav(b, true)
