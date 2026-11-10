class_name BiomeLevel
extends Node3D
## Assembles a whole biome from Biomes.DB[GameState.biome_id] and the player's
## chosen animal: terrain, scenery, water, food, cover, camp, wildlife, Shikari,
## environment (day/night, seasons, weather) and HUD.
##
## Rule used everywhere: set `position` BEFORE add_child() so _ready() sees it.

const GEAR_OFFSETS := [Vector2(-1.8, 2.8), Vector2(2.4, -3.0), Vector2(5.5, 3.8), Vector2(-5.5, -4.0), Vector2(0.5, 5.5)]
const SHIKARI_SHIRTS := [Color(0.55, 0.5, 0.35), Color(0.35, 0.45, 0.4), Color(0.5, 0.35, 0.3)]

var cfg: Dictionary = {}
var terrain: BiomeTerrain
var player: PlayerAnimal
var env: EnvironmentController
var hud: HUD

var _rng := RandomNumberGenerator.new()
var _plan: Dictionary = {}
var _targets: Dictionary = {}
var _danger := 0.0
var _danger_timer := 0.0
var _eco_timer := 12.0
var _distant_timer := 25.0
var _shikari_count := 0


func _ready() -> void:
	cfg = Biomes.DB[GameState.biome_id]
	GameState.half_size = float(cfg["size"]) * 0.5
	GameState.step_sound = cfg["step"]
	GameState.visibility_mult = 1.0
	GameState.track_life_mult = 1.0
	_rng.seed = int(cfg["seed"])
	_apply_quality()

	_build_terrain()
	Decor.build(self, terrain, _rng, GameState.biome_id, cfg["flora"])
	_spawn_world_props()
	_spawn_player()
	_spawn_wildlife()
	_spawn_shikari()

	env = EnvironmentController.new()
	env.name = "Environment"
	add_child(env)
	env.setup(self, cfg, player, terrain)

	hud = HUD.new()
	hud.env = env
	add_child(hud)

	AudioManager.start_ambience(cfg["ambience"])
	Events.player_died.connect(_on_player_died)
	Events.toast.emit("%s - %s. %s" % [cfg["name"], Animals.DB[GameState.animal_id]["name"], "Find water first."])
	_run_tutorial()


func _process(delta: float) -> void:
	_danger_timer -= delta
	if _danger_timer <= 0.0:
		_danger_timer = 0.25
		_update_danger()
	_eco_timer -= delta
	if _eco_timer <= 0.0:
		_eco_timer = 14.0
		_ecosystem_tick()
	_distant_timer -= delta
	if _distant_timer <= 0.0:
		_distant_timer = _rng.randf_range(25.0, 55.0)
		_distant_sound()


func _apply_quality() -> void:
	var q := int(SaveManager.setting("quality"))
	var scales := [0.6, 0.8, 1.0]
	get_viewport().scaling_3d_scale = scales[clampi(q, 0, 2)]


# ------------------------------------------------------------------ terrain

func _build_terrain() -> void:
	terrain = BiomeTerrain.new()
	terrain.name = "Terrain"
	terrain.configure(cfg)

	# Plan the points of interest on the raw terrain, flatten them, then build.
	_plan["water"] = terrain.low_points(_rng, int(cfg["water_count"]), 45.0, 14.0)
	_plan["camp"] = _camp_point()
	_plan["snares"] = _scatter_points(int(cfg["snares"]), 12.0, 0.7, 14.0)
	var trapped: Array[Dictionary] = []
	for entry in cfg["trapped"]:
		for i in int(entry["count"]):
			trapped.append({"species": entry["species"], "pos": _scatter_points(1, 12.0, 0.6, 28.0)[0]})
	_plan["trapped"] = trapped
	_plan["summits"] = terrain.high_points(_rng, int(cfg["summits"]), 40.0, 26.0) if int(cfg["summits"]) > 0 else []
	_plan["lookouts"] = terrain.high_points(_rng, int(cfg["lookouts"]), 40.0, 30.0) if int(cfg["lookouts"]) > 0 else []
	_plan["dens"] = _scatter_points(int(cfg["dens"]), 14.0, 0.6, 18.0)
	_plan["hide"] = _scatter_points(int(cfg["hide_count"]), 10.0, 0.7, 8.0)
	_plan["dig"] = _scatter_points(int(cfg["dig_spots"]), 10.0, 0.7, 14.0)

	terrain.add_flat_zone(Vector2.ZERO, 5.0)
	for p in _plan["water"]:
		terrain.add_flat_zone(p, 4.0)
	for p in _plan["snares"]:
		terrain.add_flat_zone(p, 2.0)
	for t in _plan["trapped"]:
		terrain.add_flat_zone(t["pos"], 2.5)
	for p in _plan["summits"]:
		terrain.add_flat_zone(p, 4.0)
	for p in _plan["lookouts"]:
		terrain.add_flat_zone(p, 4.0)
	for p in _plan["dens"]:
		terrain.add_flat_zone(p, 3.5)
	if bool(cfg["camp"]):
		terrain.add_flat_zone(_plan["camp"], 9.0)

	add_child(terrain)
	terrain.build()
	GameState.terrain = terrain


func _camp_point() -> Vector2:
	var p := Vector2(50.0, 20.0)
	for i in 40:
		p = terrain.random_point(_rng, 26.0, 0.5)
		if p.length() > 42.0 and p.length() < 85.0:
			break
	return p


func _scatter_points(count: int, margin: float, max_slope: float, min_origin: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in count:
		var p := terrain.random_point(_rng, margin, max_slope)
		for tries in 20:
			if p.length() >= min_origin:
				break
			p = terrain.random_point(_rng, margin, max_slope)
		out.append(p)
	return out


# -------------------------------------------------------------------- props

func _spawn_world_props() -> void:
	for p in _plan["water"]:
		var w := WaterSource.new()
		w.radius = cfg["water_radius"]
		w.water_color = cfg["water_color"]
		w.position = terrain.ground(p, 0.1)
		add_child(w)

	var placed := 0
	var tries := 0
	while placed < int(cfg["food_count"]) and tries < 200:
		tries += 1
		var p := terrain.random_point(_rng, 10.0, 0.7)
		if p.length() < 6.0:
			continue
		var f := FoodPlant.new()
		f.kind = cfg["food_kind"]
		f.position = terrain.ground(p)
		add_child(f)
		placed += 1

	for p in _plan["hide"]:
		var z := HideZone.new()
		z.kind = cfg["hide_kind"]
		z.radius = 3.5 if cfg["hide_kind"] == "boulders" else 3.0
		z.position = terrain.ground(p)
		add_child(z)
	for p in _plan["dens"]:
		var z := HideZone.new()
		z.kind = "den"
		z.shelter = true
		z.radius = 3.2
		z.position = terrain.ground(p)
		add_child(z)

	for p in _plan["dig"]:
		var d := DigSpot.new()
		d.position = terrain.ground(p)
		add_child(d)

	for p in _plan["snares"]:
		var s := SnareTrap.new()
		s.position = terrain.ground(p, 0.05)
		add_child(s)
	for t in _plan["trapped"]:
		var ta := TrappedAnimal.new()
		ta.species = t["species"]
		ta.position = terrain.ground(t["pos"], 0.05)
		add_child(ta)

	for p in _plan["summits"]:
		_add_trigger(p, "summit", "You reached the summit!", 70.0)
	for p in _plan["lookouts"]:
		_add_trigger(p, "lookout", "Ridge lookout reached!", 0.0)

	if bool(cfg["camp"]):
		var camp: Vector2 = _plan["camp"]
		Decor.build_camp(self, terrain, camp)
		for i in mini(int(cfg["gear"]), GEAR_OFFSETS.size()):
			var g := CampGear.new()
			g.position = terrain.ground(camp + GEAR_OFFSETS[i])
			add_child(g)


func _add_trigger(p: Vector2, event_name: String, message: String, climb: float) -> void:
	var t := TriggerZone.new()
	t.event_name = event_name
	t.message = message
	t.requires_climb = climb
	t.position = terrain.ground(p)
	add_child(t)


# ------------------------------------------------------------------- actors

func _spawn_player() -> void:
	player = PlayerAnimal.new()
	player.species_id = GameState.animal_id
	player.skin_index = SaveManager.equipped_skin(GameState.animal_id)
	player.position = terrain.ground(Vector2.ZERO, 1.0)
	add_child(player)

	var h: float = AnimalModel.SPECS[GameState.animal_id]["h"]
	var rig := CameraRig.new()
	rig.target = player
	rig.configure(4.8 + h * 2.2, 1.0 + h * 0.8)
	add_child(rig)
	rig.global_position = player.global_position + Vector3(0.0, rig.height, 0.0)
	player.camera_rig = rig


func _spawn_animal(id: String, p: Vector2) -> WildlifeAI:
	var a := Species.create(id)
	a.position = terrain.ground(p, 0.6)
	add_child(a)
	return a


func _spawn_wildlife() -> void:
	for entry in cfg["spawns"]:
		var id: String = entry["species"]
		var count: int = entry["count"]
		_targets[id] = int(_targets.get(id, 0)) + count
		var far := 40.0 if Species.DB[id]["predator"] else 18.0
		var center := _far_point(far)
		for i in count:
			var p := center
			if bool(entry["group"]):
				p = center + Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-8.0, 8.0))
			else:
				p = _far_point(far)
			_spawn_animal(id, p)


func _far_point(min_dist: float) -> Vector2:
	var p := terrain.random_point(_rng, 12.0, 0.7)
	for i in 20:
		if p.length() >= min_dist:
			break
		p = terrain.random_point(_rng, 12.0, 0.7)
	return p


func _spawn_shikari() -> void:
	var info: Dictionary = cfg["shikari"]
	_shikari_count = int(info["count"])
	var ranged_count := int(info["ranged"])
	for i in _shikari_count:
		var route: Array[Vector3] = []
		if i == 0 and bool(cfg["camp"]):
			var camp: Vector2 = _plan["camp"]
			for k in 4:
				var a := float(k) / 4.0 * TAU
				route.append(terrain.ground(camp + Vector2(cos(a), sin(a)) * 13.0))
		else:
			var start := _far_point(38.0)
			for k in 4:
				var q := start + Vector2(_rng.randf_range(-35.0, 35.0), _rng.randf_range(-35.0, 35.0))
				var limit := GameState.half_size - 12.0
				q = Vector2(clampf(q.x, -limit, limit), clampf(q.y, -limit, limit))
				route.append(terrain.ground(q))
		var s := ShikariAI.new()
		s.patrol_points = route
		s.ranged = i >= _shikari_count - ranged_count
		s.shirt_color = SHIKARI_SHIRTS[i % SHIKARI_SHIRTS.size()]
		s.position = route[0] + Vector3.UP * 0.5
		add_child(s)


# ------------------------------------------------------------------- upkeep

## Keeps populations from collapsing: when a species falls below 70% of its
## target, one new animal wanders in from far away from the player.
func _ecosystem_tick() -> void:
	var counts: Dictionary = {}
	for n in get_tree().get_nodes_in_group("animals"):
		var a := n as WildlifeAI
		if a != null and not a.dead:
			counts[a.species] = int(counts.get(a.species, 0)) + 1
	for id in _targets:
		if int(counts.get(id, 0)) < int(float(_targets[id]) * 0.7):
			for i in 12:
				var p := terrain.random_point(_rng, 12.0, 0.7)
				if Vector3(p.x, 0.0, p.y).distance_to(Vector3(player.global_position.x, 0.0, player.global_position.z)) > 50.0:
					_spawn_animal(id, p)
					return


func _update_danger() -> void:
	var level := 0.0
	for n in get_tree().get_nodes_in_group("shikari"):
		var s := n as ShikariAI
		if s != null:
			level = maxf(level, s.alert_level())
	for n in get_tree().get_nodes_in_group("predators"):
		var a := n as WildlifeAI
		if a != null and a.hunting_player:
			level = maxf(level, 0.85)
	var smoothed := lerpf(_danger, level, 0.5)
	if absf(smoothed - _danger) > 0.03:
		_danger = smoothed
		Events.danger_level_changed.emit(_danger)


## Far-off calls: predator warnings and poachers' rifles.
func _distant_sound() -> void:
	if player == null:
		return
	var list: Array = cfg["distant"]
	var sound: String = list[_rng.randi() % list.size()]
	if sound == "gunshot" and _shikari_count == 0:
		sound = "fox_bark"
	var angle := _rng.randf() * TAU
	var pos := player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * _rng.randf_range(55.0, 75.0)
	AudioManager.play_3d(sound, pos, -4.0, 0.1)


func _on_player_died() -> void:
	SaveManager.set_stat_max("best_days", GameState.days_survived)


func _run_tutorial() -> void:
	if bool(SaveManager.setting("tutorial_done")):
		return
	var diet: String = Animals.DB[GameState.animal_id]["diet"]
	var tips: Array[String] = [
		"Left stick moves. Drag the right side of the screen to look around.",
		"Watch your Hunger, Thirst and Temperature bars. Drink at water, eat plants.",
		"Hide in bushes and dens to stay out of sight. Standing still recovers faster.",
		"Poachers (Shikari) patrol the land. Break line of sight and they lose you.",
		"Open the Missions list to earn coins and unlock new animals and habitats.",
	]
	if diet != "herbivore":
		tips.insert(2, "You're a predator: pounce on prey, then feed from the carcass.")
	for tip in tips:
		await get_tree().create_timer(6.0).timeout
		if not is_inside_tree():
			return
		Events.toast.emit(tip)
	SaveManager.set_setting("tutorial_done", true)
