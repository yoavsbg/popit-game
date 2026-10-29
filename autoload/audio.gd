extends Node
## All game sounds. They are synthesized at startup (self-made, no licensing) and played
## through a pool of players so fast taps overlap cleanly.

const RATE := 44100
const POOL_SIZE := 12
const COMBO_WINDOW_MS := 900
const COMBO_MAX := 10
const COMBO_STEP := 0.06

## Background music (assets/music/loop.wav, made by tools/make_music.py). It sits well below the
## effects, loops forever, fades in, and follows the global mute because it plays on Master.
const MUSIC_DB := -9.0
const MUSIC_FADE_S := 2.0

var _music := AudioStreamPlayer.new()
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _combo := 0
var _last_pop_ms := -100000

var _pop: AudioStreamWAV
var _unpop: AudioStreamWAV
var _buzz: AudioStreamWAV
var _chime: AudioStreamWAV
var _click: AudioStreamWAV
var _sparkle: AudioStreamWAV


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music.stream = load("res://assets/music/loop.wav")
	add_child(_music)
	_pop = _to_stream(_synth_pop())
	_unpop = _to_stream(_synth_unpop())
	_buzz = _to_stream(_synth_buzz())
	_chime = _to_stream(_synth_chime([1046.5, 1318.5, 1568.0], 0.11, 1.2))
	_sparkle = _to_stream(_synth_chime([1568.0, 2093.0], 0.07, 0.7))
	_click = _to_stream(_synth_click())


## Starts the looping background music with a fade-in. Does nothing if it is already playing.
func start_music() -> void:
	if _music.playing:
		return
	_music.volume_db = -50.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", MUSIC_DB, MUSIC_FADE_S)


func is_music_playing() -> bool:
	return _music.playing and not _music.stream_paused


## Pause the music while the app is in the background.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_music.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_music.stream_paused = false


## Pop with a pitch that climbs while the player keeps popping quickly.
func pop() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_pop_ms <= COMBO_WINDOW_MS:
		_combo = mini(_combo + 1, COMBO_MAX)
	else:
		_combo = 0
	_last_pop_ms = now
	_play(_pop, (1.0 + _combo * COMBO_STEP) * randf_range(0.98, 1.02))


func unpop() -> void:
	_play(_unpop, randf_range(0.95, 1.08), -10.0)


func wrong() -> void:
	_combo = 0
	_play(_buzz, 1.0, -5.0)


func chime() -> void:
	_play(_chime, 1.0, -3.0)


func sparkle() -> void:
	_play(_sparkle, 1.0, -6.0)


func click() -> void:
	_play(_click, randf_range(0.97, 1.03), -9.0)


func _play(stream: AudioStream, pitch := 1.0, volume_db := 0.0) -> void:
	if Settings.muted:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


## A soft, hollow "pock": a fast downward pitch sweep with a tiny click on the attack.
func _synth_pop() -> PackedFloat32Array:
	var n := int(RATE * 0.13)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var phase2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 210.0 + 760.0 * exp(-t * 60.0)
		phase += TAU * f / RATE
		phase2 += TAU * f * 2.01 / RATE
		var env := (1.0 - exp(-t * 2500.0)) * exp(-t * 34.0)
		var body := sin(phase) + 0.18 * sin(phase2) * exp(-t * 60.0)
		var click := randf_range(-1.0, 1.0) * exp(-t * 1400.0) * 0.22
		out[i] = (body * env * 0.85) + click
	return out


## The reverse: a short upward "bloop" used when bubbles come back.
func _synth_unpop() -> PackedFloat32Array:
	var n := int(RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 300.0 + 500.0 * (t / 0.09)
		phase += TAU * f / RATE
		var env := (1.0 - exp(-t * 900.0)) * exp(-t * 40.0)
		out[i] = sin(phase) * env * 0.6
	return out


## A low, rounded buzz for a wrong tap.
func _synth_buzz() -> PackedFloat32Array:
	var n := int(RATE * 0.24)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * 130.0 / RATE
		var wave := sin(phase) + 0.45 * sin(phase * 2.0) + 0.25 * sin(phase * 3.0)
		var env := minf(t / 0.008, 1.0) * exp(-t * 9.0)
		var tremolo := 0.75 + 0.25 * sin(TAU * 28.0 * t)
		out[i] = wave * env * tremolo * 0.42
	return out


## Bell-like rising notes.
func _synth_chime(freqs: Array, gap: float, length: float) -> PackedFloat32Array:
	var n := int(RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in freqs.size():
		var f: float = freqs[k]
		var start := int(RATE * gap * k)
		for i in range(start, n):
			var t := float(i - start) / RATE
			var env := minf(t / 0.004, 1.0) * exp(-t * 5.5)
			var v := sin(TAU * f * t) + 0.32 * sin(TAU * f * 2.0 * t) * exp(-t * 8.0) \
				+ 0.12 * sin(TAU * f * 3.01 * t) * exp(-t * 12.0)
			out[i] += v * env * 0.3
	return out


func _synth_click() -> PackedFloat32Array:
	var n := int(RATE * 0.045)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * (1300.0 - 9000.0 * t) / RATE
		out[i] = sin(phase) * exp(-t * 120.0) * 0.5
	return out
