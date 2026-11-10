class_name EnvironmentController
extends Node
## Sky, sun, fog, day/night cycle, seasons, weather and ambient temperature.
##
## Writes GameState.visibility_mult / ambient_temp / track_life_mult / is_night /
## weather / season, drives AudioManager's weather layers, and fires the
## "day_survived" and "storm_survived" mission events.

const WEATHER := {
	"clear": {"vis": 1.0, "temp": 0.0, "wind": 0.1, "rain": 0.0, "fog": 0.0, "track": 1.0, "particles": ""},
	"windy": {"vis": 0.95, "temp": -2.0, "wind": 0.75, "rain": 0.0, "fog": 0.0005, "track": 0.8, "particles": ""},
	"rain": {"vis": 0.75, "temp": -4.0, "wind": 0.35, "rain": 0.7, "fog": 0.004, "track": 0.5, "particles": "rain"},
	"storm": {"vis": 0.6, "temp": -6.0, "wind": 0.7, "rain": 1.0, "fog": 0.007, "track": 0.3, "particles": "rain_heavy", "lightning": true},
	"snow": {"vis": 0.7, "temp": -4.0, "wind": 0.3, "rain": 0.0, "fog": 0.005, "track": 0.6, "particles": "snow"},
	"blizzard": {"vis": 0.4, "temp": -10.0, "wind": 1.0, "rain": 0.0, "fog": 0.016, "track": 0.3, "particles": "blizzard"},
	"sandstorm": {"vis": 0.4, "temp": 0.0, "wind": 1.0, "rain": 0.0, "fog": 0.018, "track": 0.3, "particles": "sand", "fog_color": Color(0.8, 0.62, 0.38)},
}
const STORMS := ["storm", "blizzard", "sandstorm"]
const WEATHER_LABEL := {
	"clear": "Clear", "windy": "Windy", "rain": "Rain", "storm": "Thunderstorm",
	"snow": "Snow", "blizzard": "Blizzard", "sandstorm": "Sandstorm",
}
const SEASON_TINT := {
	"spring": Color(0.97, 1.05, 0.95), "summer": Color(1.05, 1.0, 0.92),
	"autumn": Color(1.08, 0.94, 0.8), "winter": Color(0.92, 0.96, 1.02),
}
const SNOW_BY_SEASON := {"spring": 0.35, "summer": 0.0, "autumn": 0.35, "winter": 1.0}

var weather := "clear"
var intensity := 0.0
var hour := 8.0
var day := 0
var season := "summer"

var _cfg: Dictionary = {}
var _terrain: BiomeTerrain
var _player: PlayerAnimal
var _rng := RandomNumberGenerator.new()
var _sun: DirectionalLight3D
var _env: Environment
var _sky: ProceduralSkyMaterial
var _particles: CPUParticles3D
var _particle_mat: StandardMaterial3D
var _particle_kind := ""
var _particle_alpha := 0.5
var _wind_particles := false
var _start_season := 0
var _pending := ""
var _weather_timer := 60.0
var _storm_time := 0.0
var _flash := 0.0
var _lightning_timer := 6.0
var _thunder_queue: Array[float] = []
var _tick := 0.0
var _base_temp := 25.0
var _time_emit := 0.0


func setup(level: Node3D, config: Dictionary, player: PlayerAnimal, terrain: BiomeTerrain) -> void:
	_cfg = config
	_player = player
	_terrain = terrain
	_rng.randomize()
	season = config["start_season"]
	_start_season = GameConst.SEASONS.find(season)
	_base_temp = float((config["base_temp"] as Dictionary)[season])
	_weather_timer = _rng.randf_range(50.0, 100.0)
	_build_environment(level)
	_build_particles(level)
	_apply_season(false)
	GameState.weather = weather
	_update_visuals()
	_update_temperature(0.2)
	Events.weather_changed.emit(weather)


func _process(delta: float) -> void:
	if _player == null:
		return
	_advance_time(delta)
	_update_weather(delta)
	_update_lightning(delta)
	_particles.global_position = _player.global_position + (Vector3(-11.0, 4.0, 0.0) if _wind_particles else Vector3(0.0, 9.0, 0.0))
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.2
		_update_visuals()
		_update_temperature(0.2)
		_update_audio()
	_time_emit -= delta
	if _time_emit <= 0.0:
		_time_emit = 0.5
		Events.time_changed.emit(hour, day + 1, season)


# ------------------------------------------------------------------ setup

func _build_environment(level: Node3D) -> void:
	_sky = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_density = _cfg["fog_density"]
	var we := WorldEnvironment.new()
	we.environment = _env
	level.add_child(we)

	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = int(SaveManager.setting("quality")) > 0
	_sun.directional_shadow_max_distance = 70.0
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	level.add_child(_sun)


func _build_particles(level: Node3D) -> void:
	_particles = CPUParticles3D.new()
	_particles.emitting = false
	_particles.local_coords = false
	_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_particles_mat_init()
	level.add_child(_particles)


func _particles_mat_init() -> void:
	_particle_mat = StandardMaterial3D.new()
	_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_particle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_particle_mat.albedo_color = Color(1, 1, 1, 0.0)


func _configure_particles(kind: String) -> void:
	_particle_kind = kind
	_wind_particles = false
	if kind == "":
		_particles.emitting = false
		return
	var quad := QuadMesh.new()
	var color := Color(1, 1, 1, 0.5)
	match kind:
		"rain":
			_set_particles(350, 0.9, Vector3(0.2, -1.0, 0.0), 3.0, 22.0, 26.0, Vector3(0.0, -6.0, 0.0), Vector3(16.0, 0.5, 16.0))
			quad.size = Vector2(0.03, 0.5)
			color = Color(0.75, 0.8, 0.9, 0.45)
		"rain_heavy":
			_set_particles(600, 0.8, Vector3(0.45, -1.0, 0.0), 4.0, 28.0, 32.0, Vector3(0.0, -8.0, 0.0), Vector3(16.0, 0.5, 16.0))
			quad.size = Vector2(0.03, 0.6)
			color = Color(0.7, 0.75, 0.88, 0.55)
		"snow":
			_set_particles(400, 4.0, Vector3(0.1, -1.0, 0.0), 25.0, 1.5, 2.5, Vector3(0.0, -0.4, 0.0), Vector3(16.0, 0.5, 16.0))
			quad.size = Vector2(0.1, 0.1)
			color = Color(1, 1, 1, 0.9)
		"blizzard":
			_wind_particles = true
			_set_particles(700, 1.8, Vector3(0.9, -0.25, 0.2), 15.0, 9.0, 12.0, Vector3(0.0, -1.0, 0.0), Vector3(4.0, 6.0, 16.0))
			quad.size = Vector2(0.12, 0.12)
			color = Color(1, 1, 1, 0.85)
		"sand":
			_wind_particles = true
			_set_particles(500, 1.6, Vector3(1.0, 0.1, 0.3), 12.0, 10.0, 14.0, Vector3.ZERO, Vector3(4.0, 6.0, 16.0))
			quad.size = Vector2(0.35, 0.08)
			color = Color(0.85, 0.68, 0.42, 0.5)
	_particle_alpha = color.a
	_particle_mat.albedo_color = Color(color.r, color.g, color.b, 0.0)
	quad.material = _particle_mat
	_particles.mesh = quad
	_particles.emitting = true


func _set_particles(amount: int, lifetime: float, direction: Vector3, spread: float, v_min: float, v_max: float, gravity: Vector3, extents: Vector3) -> void:
	_particles.amount = amount
	_particles.lifetime = lifetime
	_particles.preprocess = lifetime
	_particles.direction = direction
	_particles.spread = spread
	_particles.initial_velocity_min = v_min
	_particles.initial_velocity_max = v_max
	_particles.gravity = gravity
	_particles.emission_box_extents = extents


# ----------------------------------------------------------------- time

func _advance_time(delta: float) -> void:
	hour += delta * 24.0 / GameConst.DAY_LENGTH
	if hour < 24.0:
		return
	hour -= 24.0
	day += 1
	GameState.days_survived = day
	SaveManager.bump_stat("total_days")
	SaveManager.set_stat_max("best_days", day)
	SaveManager.add_coins(10)
	Events.game_event.emit("day_survived")
	Events.toast.emit("Day %d survived  (+10 coins)" % day)
	var idx := (_start_season + day / GameConst.SEASON_DAYS) % GameConst.SEASONS.size()
	if GameConst.SEASONS[idx] != season:
		season = GameConst.SEASONS[idx]
		_apply_season(true)


func _apply_season(announce: bool) -> void:
	GameState.season = season
	var snow := float(SNOW_BY_SEASON[season]) * float(_cfg["winter_snow"])
	_terrain.set_season(SEASON_TINT[season], snow)
	if announce:
		Events.toast.emit("The season changes: %s" % season.capitalize())


# --------------------------------------------------------------- weather

func _pick_weather() -> String:
	var weights: Dictionary = (_cfg["weather"] as Dictionary).duplicate()
	if season == "winter":
		if weights.has("rain"):
			weights["snow"] = weights["rain"]
			weights.erase("rain")
		if weights.has("storm"):
			weights["blizzard"] = weights["storm"]
			weights.erase("storm")
	elif season == "summer":
		if weights.has("snow"):
			weights["clear"] = int(weights["clear"]) + int(weights["snow"])
			weights.erase("snow")
		if weights.has("blizzard"):
			weights["windy"] = int(weights["windy"]) + int(weights["blizzard"])
			weights.erase("blizzard")
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var roll := _rng.randf() * total
	for k in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return "clear"


func _update_weather(delta: float) -> void:
	_weather_timer -= delta
	if _pending == "" and _weather_timer <= 0.0:
		var next := _pick_weather()
		if next != weather:
			_pending = next
		else:
			_weather_timer = _rng.randf_range(50.0, 110.0)
	if _pending != "":
		intensity = move_toward(intensity, 0.0, delta * 0.18)
		if intensity <= 0.01:
			_end_weather()
			weather = _pending
			_pending = ""
			_weather_timer = _rng.randf_range(60.0, 140.0)
			GameState.weather = weather
			Events.weather_changed.emit(weather)
			if weather != "clear":
				Events.toast.emit("Weather: %s" % WEATHER_LABEL[weather])
			_configure_particles(WEATHER[weather]["particles"])
	else:
		intensity = move_toward(intensity, 1.0, delta * 0.1)
	if STORMS.has(weather) and intensity > 0.5 and not _player.stats.dead:
		_storm_time += delta


func _end_weather() -> void:
	if STORMS.has(weather) and _storm_time > 30.0:
		Events.toast.emit("You survived the %s." % WEATHER_LABEL[weather].to_lower())
		Events.game_event.emit("storm_survived")
	_storm_time = 0.0


func _update_lightning(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 4.0)
	for i in range(_thunder_queue.size() - 1, -1, -1):
		_thunder_queue[i] -= delta
		if _thunder_queue[i] <= 0.0:
			_thunder_queue.remove_at(i)
			AudioManager.play_ui("thunder", -3.0)
	if not WEATHER[weather].get("lightning", false) or intensity < 0.6:
		return
	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_lightning_timer = _rng.randf_range(6.0, 15.0)
		_flash = 1.0
		_thunder_queue.append(_rng.randf_range(0.4, 2.8))


# --------------------------------------------------------------- visuals

func _update_visuals() -> void:
	var w: Dictionary = WEATHER[weather]
	var elev := sin((hour - 6.0) / 12.0 * PI)
	var daylight := clampf(elev * 2.0 + 0.15, 0.0, 1.0)
	var night := 1.0 - daylight
	GameState.is_night = night > 0.6

	_sun.rotation_degrees = Vector3(-(8.0 + 57.0 * maxf(elev, 0.0)), -90.0 + (hour - 6.0) * 15.0, 0.0)
	var warm := clampf(1.0 - absf(elev) * 3.0, 0.0, 1.0)
	var sun_color: Color = (_cfg["sun_color"] as Color).lerp(Color(1.0, 0.6, 0.35), warm * 0.7)
	_sun.light_color = Color(0.55, 0.65, 0.9).lerp(sun_color, daylight)
	var overcast := clampf(intensity * (1.0 if weather != "clear" and weather != "windy" else 0.0), 0.0, 1.0)
	_sun.light_energy = lerpf(0.15, float(_cfg["sun_energy"]), daylight) * (1.0 - overcast * 0.55)

	var top: Color = Color(0.02, 0.04, 0.1).lerp(_cfg["sky_top"], daylight)
	var horizon: Color = Color(0.05, 0.07, 0.14).lerp((_cfg["sky_horizon"] as Color).lerp(Color(1.0, 0.65, 0.4), warm * 0.5), daylight)
	var grey := Color(0.5, 0.53, 0.57).lerp(Color(0.04, 0.05, 0.08), night)
	if weather == "sandstorm":
		grey = Color(0.72, 0.56, 0.36).lerp(Color(0.1, 0.07, 0.04), night)
	top = top.lerp(grey, overcast * 0.8)
	horizon = horizon.lerp(grey, overcast * 0.85)
	_sky.sky_top_color = top
	_sky.sky_horizon_color = horizon
	_sky.ground_horizon_color = horizon
	_sky.ground_bottom_color = top.darkened(0.3)

	var fog_base: Color = Color(0.03, 0.04, 0.08).lerp(_cfg["fog"], daylight)
	var fog_target: Color = w.get("fog_color", grey)
	_env.fog_light_color = fog_base.lerp(fog_target, overcast * 0.85 if weather != "windy" else 0.0)
	_env.fog_density = float(_cfg["fog_density"]) + float(w["fog"]) * intensity
	_env.ambient_light_energy = lerpf(0.3, 1.0, daylight) + _flash * 2.0
	_env.background_energy_multiplier = 1.0 + _flash * 1.5

	GameState.visibility_mult = lerpf(1.0, float(w["vis"]), intensity) * lerpf(1.0, 0.7, night)
	GameState.track_life_mult = lerpf(1.0, float(w["track"]), intensity)
	_particle_mat.albedo_color.a = _particle_alpha * intensity


func _update_temperature(dt: float) -> void:
	var w: Dictionary = WEATHER[weather]
	var target := float((_cfg["base_temp"] as Dictionary)[season])
	_base_temp = lerpf(_base_temp, target, clampf(dt * 0.05, 0.0, 1.0))
	var diurnal := sin((hour - 9.0) / 24.0 * TAU)
	GameState.ambient_temp = _base_temp + float(_cfg["day_swing"]) * diurnal + float(w["temp"]) * intensity


func _update_audio() -> void:
	var w: Dictionary = WEATHER[weather]
	var night := 1.0 - clampf(sin((hour - 6.0) / 12.0 * PI) * 2.0 + 0.15, 0.0, 1.0)
	AudioManager.set_environment(float(w["wind"]) * intensity, float(w["rain"]) * intensity, night)


## "Day 3  Autumn  14:30  Clear  12C"
func status_text() -> String:
	var h := int(hour)
	var m := int((hour - h) * 60.0)
	return "Day %d  |  %s  |  %02d:%02d  |  %s  |  %d C" % [day + 1, season.capitalize(), h, m, WEATHER_LABEL[weather], roundi(GameState.ambient_temp)]
