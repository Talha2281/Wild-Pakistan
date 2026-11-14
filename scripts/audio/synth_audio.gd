class_name SynthAudio
extends RefCounted
## Procedural placeholder sound effects and ambience, generated in code at run time.
## This lets the whole game have sound with zero audio files. Real recordings dropped
## into assets/audio/<name>.ogg automatically replace the synthesised version
## (see AudioManager and assets/audio/README.md).
##
## Sounds are small mono 16-bit buffers (11 kHz for noisy sounds, 22 kHz for tonal).

const R_LOW := 11025
const R_HI := 22050
const AMB_LEN := 4.0

const LOOPS := ["music_menu", "music_game", "amb_desert", "amb_forest", "amb_mountain", "wind", "rain", "night", "heartbeat"]


static func make(sound: String) -> AudioStreamWAV:
	match sound:
		"amb_desert", "amb_forest", "amb_mountain":
			return _ambient(sound)
		"music_menu":
			return _music(false)
		"music_game":
			return _music(true)
		"orb":
			return _orb()
		"combo":
			return _combo()
		"wind":
			return _wind()
		"rain":
			return _rain()
		"night":
			return _night()
		"heartbeat":
			return _heartbeat()
		"step_sand":
			return _step(0)
		"step_grass":
			return _step(1)
		"step_snow":
			return _step(2)
		"step_human":
			return _step(3)
		"drink":
			return _drink()
		"eat":
			return _eat()
		"dig":
			return _dig()
		"jump":
			return _whoosh(0.3, 0.35)
		"swipe":
			return _whoosh(0.25, 0.6)
		"hit":
			return _hit()
		"trap_snap":
			return _trap()
		"gunshot":
			return _gunshot()
		"thunder":
			return _thunder()
		"roar":
			return _roar()
		"bear_growl":
			return _growl(55.0, 0.9, 18.0)
		"leopard_growl":
			return _growl(95.0, 0.8, 26.0)
		"howl":
			return _howl()
		"snort":
			return _snort()
		"fox_bark":
			return _bark()
		"bleat":
			return _bleat()
		"whistle":
			return _squeak(2600.0, 2100.0, 0.4)
		"shikari_shout":
			return _shout()
		"shikari_whistle":
			return _squeak(1400.0, 2200.0, 0.6)
		"chime":
			return _chime()
		"click":
			return _click()
		"bird":
			return _bird()
		"chirp_a":
			return _chirp_a()
		"chirp_b":
			return _chirp_b()
		"cuckoo":
			return _cuckoo()
		"owl":
			return _owl()
		"cricket":
			return _cricket()
		"frog":
			return _frog()
		"eagle":
			return _eagle()
		"crow":
			return _crow()
		"ram_bleat":
			return _ram_bleat()
		"boar_grunt":
			return _growl(130.0, 0.45, 14.0)
		"hyena_laugh":
			return _hyena()
		"hiss":
			return _hiss()
		"hare_squeal":
			return _squeak(1900.0, 900.0, 0.35)
		"deer_cry":
			return _squeak(950.0, 520.0, 0.55)
		"dolphin":
			return _dolphin()
		"splash":
			return _splash()
	return null


# ------------------------------------------------------------------- toolkit

static func _buf(seconds: float, rate: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b


static func _noise_buf(n: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = randf() * 2.0 - 1.0
	return b


## One-pole low-pass. a is 0..1 (higher = brighter).
static func _lp(x: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(x.size())
	var y := 0.0
	for i in x.size():
		y += a * (x[i] - y)
		out[i] = y
	return out


static func _hp(x: PackedFloat32Array, a: float) -> PackedFloat32Array:
	var low := _lp(x, a)
	var out := PackedFloat32Array()
	out.resize(x.size())
	for i in x.size():
		out[i] = x[i] - low[i]
	return out


static func _noise_burst(buf: PackedFloat32Array, rate: int, t0: float, dur: float, amp: float, decay: float, a: float) -> void:
	var start := int(t0 * rate)
	var n := mini(int(dur * rate), buf.size() - start)
	if n <= 0:
		return
	var raw := _lp(_noise_buf(n), a)
	for i in n:
		var t := float(i) / rate
		buf[start + i] += raw[i] * amp * exp(-t * decay) * minf(1.0, t / 0.004)


## shape: 0 sine, 1 saw, 2 sine with harmonics
static func _tone(buf: PackedFloat32Array, rate: int, t0: float, dur: float, f0: float, f1: float, amp: float, shape: int, decay: float, vib_hz := 0.0, vib_depth := 0.0) -> void:
	var start := int(t0 * rate)
	var n := mini(int(dur * rate), buf.size() - start)
	if n <= 0:
		return
	var phase := 0.0
	for i in n:
		var t := float(i) / rate
		var k := t / dur
		var f := lerpf(f0, f1, k) + sin(TAU * vib_hz * t) * vib_depth
		phase += TAU * f / rate
		var s := 0.0
		match shape:
			0:
				s = sin(phase)
			1:
				s = 2.0 * fposmod(phase / TAU, 1.0) - 1.0
			_:
				s = sin(phase) + 0.5 * sin(2.0 * phase) + 0.25 * sin(3.0 * phase)
		var env := minf(1.0, t / 0.01) * exp(-t * decay) * minf(1.0, (dur - t) / (dur * 0.2))
		buf[start + i] += s * amp * env


static func _wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.85 / peak
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


## Makes a noise-based buffer loop without a click: the last `fade` samples are
## folded into the start with an equal-power crossfade. raw.size() must be n + fade.
static func _loopify(raw: PackedFloat32Array, n: int, fade: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		if i < fade:
			var t := float(i) / float(fade)
			out[i] = raw[i] * sin(t * PI * 0.5) + raw[n + i] * cos(t * PI * 0.5)
		else:
			out[i] = raw[i]
	return out


# ------------------------------------------------------------------ ambience

static func _ambient(kind: String) -> AudioStreamWAV:
	var rate := R_LOW
	var n := int(AMB_LEN * rate)
	var fade := int(0.4 * rate)
	var a := 0.06
	if kind == "amb_forest":
		a = 0.045
	elif kind == "amb_mountain":
		a = 0.03
	var raw := _lp(_noise_buf(n + fade), a)
	for i in raw.size():
		var t := float(i) / rate
		var lfo := 0.65 + 0.35 * sin(TAU * t / AMB_LEN) * sin(TAU * 2.0 * t / AMB_LEN + 1.0)
		raw[i] *= lfo
	if kind != "amb_mountain":
		var rng := RandomNumberGenerator.new()
		rng.seed = 11 if kind == "amb_forest" else 29
		var count := 4 if kind == "amb_forest" else 2
		for c in count:
			var t0 := rng.randf_range(0.6, AMB_LEN - 1.2)
			var f0 := rng.randf_range(2600.0, 3600.0)
			for k in 3:
				_tone(raw, rate, t0 + k * 0.11, 0.08, f0, f0 * 1.25, 0.1, 0, 6.0)
	return _wav(_loopify(raw, n, fade), rate, true)


static func _wind() -> AudioStreamWAV:
	var rate := R_LOW
	var length := 3.0
	var n := int(length * rate)
	var fade := int(0.4 * rate)
	var raw := _lp(_noise_buf(n + fade), 0.12)
	for i in raw.size():
		var t := float(i) / rate
		var g := 0.5 + 0.5 * sin(TAU * t / length)
		var h := 0.5 + 0.5 * sin(TAU * 3.0 * t / length + 2.0)
		raw[i] *= 0.35 + 0.65 * g * h
	return _wav(_loopify(raw, n, fade), rate, true)


static func _rain() -> AudioStreamWAV:
	var rate := R_LOW
	var n := int(2.5 * rate)
	var fade := int(0.3 * rate)
	var raw := _noise_buf(n + fade)
	raw = _lp(_hp(raw, 0.15), 0.7)
	return _wav(_loopify(raw, n, fade), rate, true)


static func _night() -> AudioStreamWAV:
	var rate := R_HI
	var length := 3.0
	var b := _buf(length, rate)
	for i in b.size():
		var t := float(i) / rate
		var gate1 := maxf(0.0, sin(TAU * 16.0 * t)) * (1.0 if sin(TAU * 2.0 * t) > 0.0 else 0.0)
		var gate2 := maxf(0.0, sin(TAU * 13.0 * t)) * (1.0 if sin(TAU * 1.0 * t + 1.0) > 0.0 else 0.0)
		b[i] = 0.5 * gate1 * sin(TAU * 4300.0 * t) + 0.4 * gate2 * sin(TAU * 3700.0 * t)
	return _wav(b, rate, true)


static func _heartbeat() -> AudioStreamWAV:
	var rate := R_LOW
	var b := _buf(1.0, rate)
	_tone(b, rate, 0.0, 0.18, 62.0, 42.0, 1.0, 0, 14.0)
	_tone(b, rate, 0.3, 0.15, 55.0, 40.0, 0.7, 0, 16.0)
	return _wav(b, rate, true)


# ---------------------------------------------------------------- one-shots

static func _step(kind: int) -> AudioStreamWAV:
	var b := _buf(0.22, R_LOW)
	match kind:
		0:
			_noise_burst(b, R_LOW, 0.0, 0.18, 0.8, 26.0, 0.22)
			_tone(b, R_LOW, 0.0, 0.1, 90.0, 60.0, 0.35, 0, 40.0)
		1:
			_noise_burst(b, R_LOW, 0.0, 0.16, 0.7, 22.0, 0.5)
			_noise_burst(b, R_LOW, 0.05, 0.1, 0.4, 30.0, 0.6)
		2:
			_noise_burst(b, R_LOW, 0.0, 0.18, 0.7, 14.0, 0.45)
			_noise_burst(b, R_LOW, 0.07, 0.12, 0.5, 20.0, 0.6)
		_:
			_tone(b, R_LOW, 0.0, 0.14, 75.0, 50.0, 0.9, 0, 30.0)
			_noise_burst(b, R_LOW, 0.0, 0.1, 0.4, 35.0, 0.2)
	return _wav(b, R_LOW, false)


static func _drink() -> AudioStreamWAV:
	var b := _buf(0.9, R_LOW)
	_noise_burst(b, R_LOW, 0.0, 0.9, 0.15, 2.0, 0.12)
	for k in 6:
		var t0 := randf() * 0.7
		_tone(b, R_LOW, t0, 0.1, 350.0 + randf() * 200.0, 800.0 + randf() * 300.0, 0.6, 0, 25.0)
	return _wav(b, R_LOW, false)


static func _eat() -> AudioStreamWAV:
	var b := _buf(0.65, R_LOW)
	for t0 in [0.0, 0.14, 0.3, 0.46]:
		_noise_burst(b, R_LOW, t0, 0.09, 0.9, 40.0, 0.55)
	return _wav(b, R_LOW, false)


static func _dig() -> AudioStreamWAV:
	var b := _buf(0.7, R_LOW)
	for t0 in [0.0, 0.22, 0.44]:
		_noise_burst(b, R_LOW, t0, 0.15, 0.8, 8.0, 0.3)
		_tone(b, R_LOW, t0, 0.08, 110.0, 70.0, 0.4, 0, 30.0)
	return _wav(b, R_LOW, false)


static func _whoosh(dur: float, bright: float) -> AudioStreamWAV:
	var n := int(dur * R_LOW)
	var raw := _lp(_noise_buf(n), bright * 0.4 + 0.05)
	var b := _buf(dur, R_LOW)
	for i in n:
		b[i] = raw[i] * sin(PI * float(i) / float(n))
	return _wav(b, R_LOW, false)


static func _hit() -> AudioStreamWAV:
	var b := _buf(0.2, R_LOW)
	_tone(b, R_LOW, 0.0, 0.15, 120.0, 60.0, 0.9, 0, 25.0)
	_noise_burst(b, R_LOW, 0.0, 0.1, 0.5, 30.0, 0.3)
	return _wav(b, R_LOW, false)


static func _trap() -> AudioStreamWAV:
	var b := _buf(0.4, R_HI)
	_tone(b, R_HI, 0.0, 0.2, 1800.0, 1500.0, 0.8, 2, 50.0)
	_tone(b, R_HI, 0.0, 0.15, 2700.0, 2400.0, 0.4, 0, 60.0)
	_noise_burst(b, R_HI, 0.0, 0.12, 0.8, 60.0, 0.8)
	return _wav(b, R_HI, false)


static func _gunshot() -> AudioStreamWAV:
	var b := _buf(1.3, R_LOW)
	_noise_burst(b, R_LOW, 0.0, 0.5, 1.0, 14.0, 0.6)
	_noise_burst(b, R_LOW, 0.0, 0.06, 1.0, 120.0, 0.95)
	_tone(b, R_LOW, 0.0, 0.4, 70.0, 40.0, 0.9, 0, 8.0)
	_noise_burst(b, R_LOW, 0.25, 0.8, 0.18, 4.0, 0.1)
	return _wav(b, R_LOW, false)


static func _thunder() -> AudioStreamWAV:
	var length := 3.6
	var n := int(length * R_LOW)
	var raw := _lp(_noise_buf(n), 0.03)
	var b := _buf(length, R_LOW)
	for i in n:
		var t := float(i) / R_LOW
		var env := (1.0 - exp(-t * 20.0)) * exp(-t * 0.9) * (0.6 + 0.4 * sin(t * 11.0))
		b[i] = raw[i] * env
	_noise_burst(b, R_LOW, 0.0, 0.15, 0.4, 30.0, 0.4)
	return _wav(b, R_LOW, false)


static func _roar() -> AudioStreamWAV:
	var b := _buf(1.5, R_HI)
	_tone(b, R_HI, 0.0, 1.4, 75.0, 55.0, 0.8, 1, 0.8, 7.0, 8.0)
	_noise_burst(b, R_HI, 0.0, 1.4, 0.5, 1.2, 0.15)
	return _wav(_lp(b, 0.35), R_HI, false)


static func _growl(f: float, dur: float, am_hz: float) -> AudioStreamWAV:
	var b := _buf(dur, R_HI)
	_tone(b, R_HI, 0.0, dur, f, f * 0.8, 0.8, 1, 1.0, 5.0, 4.0)
	_noise_burst(b, R_HI, 0.0, dur, 0.3, 2.0, 0.2)
	for i in b.size():
		var t := float(i) / R_HI
		b[i] *= 0.6 + 0.4 * sin(TAU * am_hz * t)
	return _wav(_lp(b, 0.4), R_HI, false)


static func _howl() -> AudioStreamWAV:
	var length := 2.6
	var b := _buf(length, R_HI)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / R_HI
		var k := t / length
		var f := 380.0 + 180.0 * sin(PI * k) + sin(TAU * 5.0 * t) * 12.0
		phase += TAU * f / R_HI
		var env := pow(sin(PI * k), 0.6)
		b[i] = (sin(phase) + 0.4 * sin(2.0 * phase)) * env
	return _wav(b, R_HI, false)


static func _snort() -> AudioStreamWAV:
	var b := _buf(0.4, R_LOW)
	_noise_burst(b, R_LOW, 0.0, 0.15, 1.0, 18.0, 0.45)
	_noise_burst(b, R_LOW, 0.17, 0.15, 0.8, 18.0, 0.45)
	return _wav(b, R_LOW, false)


static func _bark() -> AudioStreamWAV:
	var b := _buf(0.6, R_HI)
	for st in [0.0, 0.28]:
		_tone(b, R_HI, st, 0.14, 720.0, 420.0, 0.8, 2, 8.0)
		_noise_burst(b, R_HI, st, 0.14, 0.2, 10.0, 0.4)
	return _wav(b, R_HI, false)


static func _bleat() -> AudioStreamWAV:
	var b := _buf(0.8, R_HI)
	_tone(b, R_HI, 0.0, 0.7, 360.0, 330.0, 0.8, 1, 1.5, 30.0, 45.0)
	return _wav(_lp(b, 0.3), R_HI, false)


static func _ram_bleat() -> AudioStreamWAV:
	var b := _buf(0.9, R_HI)
	_tone(b, R_HI, 0.0, 0.8, 250.0, 215.0, 0.8, 1, 1.2, 28.0, 40.0)
	_noise_burst(b, R_HI, 0.0, 0.8, 0.12, 2.0, 0.3)
	return _wav(_lp(b, 0.3), R_HI, false)


static func _hyena() -> AudioStreamWAV:
	var b := _buf(1.1, R_HI)
	for i in 7:
		_tone(b, R_HI, float(i) * 0.13, 0.11, 520.0 + float(i) * 25.0, 400.0, 0.8, 2, 6.0)
	return _wav(_lp(b, 0.5), R_HI, false)


static func _hiss() -> AudioStreamWAV:
	var b := _buf(0.8, R_LOW)
	_noise_burst(b, R_LOW, 0.0, 0.7, 0.9, 2.5, 0.75)
	return _wav(b, R_LOW, false)


static func _dolphin() -> AudioStreamWAV:
	var b := _buf(0.9, R_HI)
	_tone(b, R_HI, 0.0, 0.45, 2300.0, 5200.0, 0.7, 0, 1.5, 6.0, 120.0)
	for i in 6:
		_tone(b, R_HI, 0.5 + float(i) * 0.06, 0.03, 4200.0, 3000.0, 0.6, 2, 30.0)
	return _wav(b, R_HI, false)


static func _squeak(f0: float, f1: float, dur: float) -> AudioStreamWAV:
	var b := _buf(dur + 0.05, R_HI)
	_tone(b, R_HI, 0.0, dur, f0, f1, 0.8, 0, 2.0, 14.0, 80.0)
	return _wav(b, R_HI, false)


static func _shout() -> AudioStreamWAV:
	var b := _buf(0.9, R_HI)
	_tone(b, R_HI, 0.0, 0.35, 150.0, 190.0, 0.8, 1, 3.0, 6.0, 10.0)
	_tone(b, R_HI, 0.38, 0.45, 190.0, 120.0, 0.8, 1, 3.0, 6.0, 10.0)
	return _wav(_lp(b, 0.25), R_HI, false)


static func _chime() -> AudioStreamWAV:
	var b := _buf(0.8, R_HI)
	_tone(b, R_HI, 0.0, 0.6, 880.0, 880.0, 0.7, 0, 6.0)
	_tone(b, R_HI, 0.1, 0.6, 1320.0, 1320.0, 0.5, 0, 6.0)
	return _wav(b, R_HI, false)


static func _click() -> AudioStreamWAV:
	var b := _buf(0.08, R_LOW)
	_tone(b, R_LOW, 0.0, 0.05, 900.0, 700.0, 0.8, 0, 60.0)
	return _wav(b, R_LOW, false)


## Fast trill, like a sparrow or bulbul.
static func _chirp_a() -> AudioStreamWAV:
	var b := _buf(0.7, R_HI)
	var f0 := randf_range(3200.0, 4200.0)
	for k in 7:
		_tone(b, R_HI, k * 0.065, 0.05, f0 + k * 90.0, f0 * 1.2 + k * 60.0, 0.6, 0, 18.0)
	return _wav(b, R_HI, false)


## Two clear whistled notes, like a shama or oriole.
static func _chirp_b() -> AudioStreamWAV:
	var b := _buf(0.9, R_HI)
	var f0 := randf_range(1900.0, 2500.0)
	_tone(b, R_HI, 0.0, 0.28, f0, f0 * 1.35, 0.7, 0, 3.0, 22.0, 60.0)
	_tone(b, R_HI, 0.34, 0.4, f0 * 1.3, f0 * 0.8, 0.7, 0, 3.0, 18.0, 70.0)
	return _wav(b, R_HI, false)


## Hoopoe style "oop-oop-oop".
static func _cuckoo() -> AudioStreamWAV:
	var b := _buf(1.2, R_HI)
	for k in 3:
		_tone(b, R_HI, k * 0.3, 0.2, 520.0, 470.0, 0.9, 0, 5.0)
	return _wav(_lp(b, 0.5), R_HI, false)


static func _owl() -> AudioStreamWAV:
	var b := _buf(1.6, R_LOW)
	_tone(b, R_LOW, 0.0, 0.45, 420.0, 360.0, 0.8, 0, 2.5, 5.0, 8.0)
	_tone(b, R_LOW, 0.7, 0.7, 400.0, 300.0, 0.9, 0, 1.8, 5.0, 8.0)
	_noise_burst(b, R_LOW, 0.0, 1.4, 0.05, 2.0, 0.2)
	return _wav(b, R_LOW, false)


static func _cricket() -> AudioStreamWAV:
	var b := _buf(1.6, R_HI)
	for k in 12:
		var t0 := k * 0.12
		_tone(b, R_HI, t0, 0.07, 4300.0, 4400.0, 0.5, 0, 12.0)
		_tone(b, R_HI, t0 + 0.035, 0.05, 4500.0, 4500.0, 0.3, 0, 14.0)
	return _wav(b, R_HI, false)


static func _frog() -> AudioStreamWAV:
	var b := _buf(1.0, R_LOW)
	for k in 3:
		_tone(b, R_LOW, k * 0.28, 0.18, 190.0, 150.0, 0.8, 1, 5.0, 38.0, 25.0)
	return _wav(_lp(b, 0.35), R_LOW, false)


static func _eagle() -> AudioStreamWAV:
	var b := _buf(1.5, R_HI)
	_tone(b, R_HI, 0.0, 1.0, 2900.0, 1700.0, 0.7, 0, 1.6, 26.0, 120.0)
	_tone(b, R_HI, 0.0, 1.0, 5800.0, 3400.0, 0.15, 0, 2.5, 26.0, 200.0)
	return _wav(b, R_HI, false)


static func _crow() -> AudioStreamWAV:
	var b := _buf(1.0, R_HI)
	for k in 2:
		_tone(b, R_HI, k * 0.33, 0.25, 480.0, 360.0, 0.9, 1, 4.0, 55.0, 40.0)
	return _wav(_lp(b, 0.4), R_HI, false)


static func _splash() -> AudioStreamWAV:
	var b := _buf(0.6, R_HI)
	_noise_burst(b, R_HI, 0.0, 0.5, 0.8, 7.0, 0.5)
	_noise_burst(b, R_HI, 0.08, 0.3, 0.5, 10.0, 0.25)
	return _wav(b, R_HI, false)


static func _bird() -> AudioStreamWAV:
	var b := _buf(0.45, R_LOW)
	var f0 := randf_range(2600.0, 3600.0)
	for k in 3:
		_tone(b, R_LOW, k * 0.11, 0.08, f0, f0 * 1.25, 0.6, 0, 6.0)
	return _wav(b, R_LOW, false)


# Background music: a Phrygian-dominant (D, Eb, F#, G, A, Bb, C) melody over a drone
# and hand-drum pulse. Menu is slow and warm; game is quicker and driving.
static func _music(game: bool) -> AudioStreamWAV:
	var bpm := 132.0 if game else 88.0
	var beat := 60.0 / bpm
	var bars := 8
	var r := R_LOW
	var b := _buf(beat * 4.0 * bars, r)
	var notes := [293.66, 311.13, 369.99, 392.0, 440.0, 466.16, 523.25, 587.33]
	var bass := [73.42, 73.42, 98.0, 73.42, 65.41, 73.42, 98.0, 110.0]
	var phrases := [
		[0, -1, 2, 3, 4, 3, 2, 1],
		[4, 5, 4, 3, 2, 3, 1, -1],
		[0, 1, 2, 4, 5, 4, 3, 2],
		[3, 2, 1, 0, 1, 2, 3, 4],
	]
	var order := [0, 1, 0, 2, 0, 1, 2, 3]
	for bar in bars:
		var t0 := bar * 4.0 * beat
		_tone(b, r, t0, beat * 3.9, bass[bar], bass[bar], 0.55, 0, 0.35)
		_tone(b, r, t0, beat * 3.9, bass[bar] * 1.5, bass[bar] * 1.5, 0.22, 0, 0.35)
		var ph: Array = phrases[order[bar]]
		for step in 8:
			var idx: int = ph[step]
			if idx < 0:
				continue
			var tt := t0 + step * beat * 0.5
			var f: float = notes[idx]
			_tone(b, r, tt, beat * 0.9, f, f, 0.32, 2, 5.0 if game else 3.5, 5.0, 2.0)
			if game and step % 2 == 0:
				_tone(b, r, tt, beat * 0.5, f * 0.5, f * 0.5, 0.12, 1, 8.0)
		for q in 4:
			var tq := t0 + q * beat
			if game or q % 2 == 0:
				_tone(b, r, tq, 0.2, 130.0, 48.0, 0.85, 0, 13.0)
			if q % 2 == 1:
				_noise_burst(b, r, tq, 0.12, 0.3 if game else 0.18, 26.0, 0.55)
			if game:
				_noise_burst(b, r, tq + beat * 0.5, 0.05, 0.14, 60.0, 0.8)
	var n := b.size()
	var fade := int(0.02 * r)
	for i in fade:
		var k := float(i) / fade
		b[i] *= k
		b[n - 1 - i] *= k
	return _wav(b, r, true)


static func _orb() -> AudioStreamWAV:
	var b := _buf(0.35, R_HI)
	_tone(b, R_HI, 0.0, 0.15, 1100.0, 1700.0, 0.7, 0, 14.0)
	_tone(b, R_HI, 0.05, 0.25, 1650.0, 2200.0, 0.55, 0, 10.0)
	return _wav(b, R_HI, false)


static func _combo() -> AudioStreamWAV:
	var b := _buf(0.7, R_HI)
	var f := [523.25, 659.25, 783.99, 1046.5]
	for i in 4:
		_tone(b, R_HI, i * 0.09, 0.3, f[i], f[i], 0.6, 0, 7.0)
	return _wav(b, R_HI, false)
