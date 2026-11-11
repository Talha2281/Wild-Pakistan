extends Node
## Positional 3D audio plus layered ambience that reacts to weather, time of day
## and danger. Every sound is synthesised by SynthAudio unless a recording named
## assets/audio/<sound>.ogg|.wav|.mp3 exists, in which case the file wins.
##
## Buses (created at start): Master, SFX, Ambience.

const SOUND_DIR := "res://assets/audio/"
const POOL_SIZE := 14
const EXTENSIONS := [".ogg", ".wav", ".mp3"]
## Sounds generated in the background right after a level starts so the first
## time they play there is no hitch.
const WARM_UP := [
	"step_sand", "step_grass", "step_snow", "step_human", "drink", "eat", "jump",
	"snort", "fox_bark", "bleat", "shikari_shout", "shikari_whistle", "trap_snap",
	"gunshot", "hit", "swipe", "chime", "click", "roar", "bear_growl", "leopard_growl",
	"thunder", "howl", "whistle", "dig",
]

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _layers: Dictionary = {}
var _layer_target: Dictionary = {}
var _bed_name := ""
var _danger := 0.0
var _wind := 0.0
var _rain := 0.0
var _night := 0.0
var _sfx_bus := 0
var _amb_bus := 0
var _music_bus := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _music_db := -10.0
var _unlocked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_bus = _ensure_bus("SFX")
	_amb_bus = _ensure_bus("Ambience")
	_music_bus = _ensure_bus("Music")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	apply_volumes()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 80.0
		p.unit_size = 7.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 4:
		var u := AudioStreamPlayer.new()
		u.bus = "SFX"
		add_child(u)
		_ui_pool.append(u)
	Events.danger_level_changed.connect(func(level: float) -> void: _danger = level)


func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(SaveManager.setting("master")), 0.0001)))
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(float(SaveManager.setting("sfx")), 0.0001)))
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(float(SaveManager.setting("music")), 0.0001)))
	AudioServer.set_bus_volume_db(_amb_bus, linear_to_db(maxf(float(SaveManager.setting("ambience")), 0.0001)))


# ------------------------------------------------------------------- music

## Looping background music. Safe to call every scene; the same track keeps playing.
func play_music(track: String, volume_db := -10.0) -> void:
	_music_db = volume_db
	if _music_name == track and _music.playing:
		_music.volume_db = volume_db
		return
	_music_name = track
	_music.stream = _get_stream(track)
	_music.volume_db = -60.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", volume_db, 1.5)


## Browsers keep audio muted until the first tap/click. On that first input restart
## everything that should already be playing so sound is always heard.
func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey:
		if not event.is_pressed():
			return
		_unlocked = true
		if _music.stream != null:
			_music.play()
		for key in _layers:
			var p: AudioStreamPlayer = _layers[key]
			if p.stream != null:
				p.play()


# ---------------------------------------------------------------- ambience

## Starts the ambient layers for a level. bed is "amb_desert" / "amb_forest" / "amb_mountain".
func start_ambience(bed: String) -> void:
	stop_ambience()
	_bed_name = bed
	_make_layer("bed", bed, -4.0)
	_make_layer("wind", "wind", -14.0)
	_make_layer("rain", "rain", -10.0)
	_make_layer("night", "night", -16.0)
	_make_layer("heartbeat", "heartbeat", -4.0)
	_wind = 0.0
	_rain = 0.0
	_night = 0.0
	_danger = 0.0
	warm_up()


func stop_ambience() -> void:
	for key in _layers:
		var p: AudioStreamPlayer = _layers[key]
		p.stop()
		p.queue_free()
	_layers.clear()
	_layer_target.clear()


## Called by the environment controller: 0..1 each.
func set_environment(wind: float, rain: float, night: float) -> void:
	_wind = wind
	_rain = rain
	_night = night


func _make_layer(key: String, sound: String, base_db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.bus = "Ambience"
	p.volume_db = -80.0
	p.stream = _get_stream(sound)
	add_child(p)
	if p.stream != null:
		p.play()
	_layers[key] = p
	_layer_target[key] = base_db


func _process(delta: float) -> void:
	if _layers.is_empty():
		return
	var k := clampf(delta * 2.0, 0.0, 1.0)
	# Danger: birds/insects fall silent, wind dips so threats are easier to hear,
	# and a heartbeat fades in.
	var calm := 1.0 - _danger
	_fade("bed", 0.45 + 0.55 * calm, k)
	_fade("wind", clampf(0.12 + _wind * 0.9, 0.0, 1.0) * (1.0 - _danger * 0.35), k)
	_fade("rain", _rain, k)
	_fade("night", _night * calm, k)
	var hb := 0.0
	if _danger > 0.3:
		hb = (_danger - 0.3) / 0.7
	_fade("heartbeat", hb, k)


func _fade(key: String, level: float, k: float) -> void:
	var p: AudioStreamPlayer = _layers.get(key)
	if p == null:
		return
	var base: float = _layer_target[key]
	var target_db := -80.0
	if level > 0.01:
		target_db = base + linear_to_db(level)
	p.volume_db = lerpf(p.volume_db, target_db, k)
	p.stream_paused = p.volume_db < -55.0


# ----------------------------------------------------------------- one-shots

## Play a one-shot sound at a world position.
func play_3d(sound: String, pos: Vector3, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	if sound == "":
		return
	var stream := _get_stream(sound)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.global_position = pos
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


## Non-positional one-shot (UI sounds, thunder, rewards).
func play_ui(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _get_stream(sound)
	if stream == null:
		return
	for p in _ui_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


## Generates common sounds over several frames so the first use never stutters.
func warm_up() -> void:
	for s in WARM_UP:
		_get_stream(s)
		await get_tree().process_frame


func _get_stream(sound: String) -> AudioStream:
	if _streams.has(sound):
		return _streams[sound]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = SOUND_DIR + sound + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream != null:
		if SynthAudio.LOOPS.has(sound):
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			elif stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		stream = SynthAudio.make(sound)
	_streams[sound] = stream
	return stream
