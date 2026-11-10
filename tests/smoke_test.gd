extends SceneTree
## Headless smoke test. From the project folder run:
##
##   godot --headless --path . -s tests/smoke_test.gd
##
## It loads every biome with every animal that can live there, simulates a few
## seconds of play (moving, sprinting, attacking, using abilities, interacting
## with everything nearby), forces every weather type, fast-forwards a day and
## synthesises every sound. Exit code 0 = passed. Also scan the output for any
## "SCRIPT ERROR" lines: Godot prints those without failing the run.

const FRAMES := 240

var failures := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	_check_sounds()
	_check_models()
	for biome in Biomes.ORDER:
		for animal in Animals.ORDER:
			if (Animals.DB[animal]["habitats"] as Array).has(biome):
				await _test_level(biome, animal)
	print("SMOKE TEST FINISHED  failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _fail(msg: String) -> void:
	failures += 1
	printerr("FAIL: " + msg)


func _check_sounds() -> void:
	var names := ["amb_desert", "amb_forest", "amb_mountain", "wind", "rain", "night", "heartbeat",
		"step_sand", "step_grass", "step_snow", "step_human", "drink", "eat", "dig", "jump", "swipe",
		"hit", "trap_snap", "gunshot", "thunder", "roar", "bear_growl", "leopard_growl", "howl",
		"snort", "fox_bark", "bleat", "whistle", "shikari_shout", "shikari_whistle", "chime",
		"click", "bird"]
	for n in names:
		var s := SynthAudio.make(n)
		if s == null or s.data.size() < 100:
			_fail("sound " + n)
	print("sounds ok: %d" % names.size())


func _check_models() -> void:
	for id in AnimalModel.SPECS:
		var m := AnimalModel.build(id)
		if m.get_child_count() != 6:
			_fail("model %s has %d parts" % [id, m.get_child_count()])
		m.free()
	var h := AnimalModel.build_human(Color.RED, Color.BLUE, true)
	h.free()
	print("models ok: %d" % AnimalModel.SPECS.size())


func _test_level(biome: String, animal: String) -> void:
	print("--- %s / %s" % [biome, animal])
	GameState.animal_id = animal
	GameState.biome_id = biome
	var scene: PackedScene = load("res://scenes/game.tscn")
	var level := scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var player := GameState.player as PlayerAnimal
	if player == null:
		_fail("%s/%s: no player" % [biome, animal])
		level.queue_free()
		return
	var cfg: Dictionary = Biomes.DB[biome]
	var shikari_n := get_nodes_in_group("shikari").size()
	if shikari_n != int(cfg["shikari"]["count"]):
		_fail("%s: expected %d shikari, found %d" % [biome, cfg["shikari"]["count"], shikari_n])
	if get_nodes_in_group("animals").size() < 5:
		_fail("%s: too few animals" % biome)

	for i in FRAMES:
		if i == 20:
			Input.action_press("move_forward")
		if i == 60:
			Input.action_press("sprint")
		if i == 80:
			Input.action_press("attack")
		if i == 90:
			Input.action_release("attack")
			Input.action_press("ability")
		if i == 100:
			Input.action_release("ability")
		if i == 120:
			Input.action_press("jump")
		if i == 130:
			Input.action_release("jump")
		if i == 150:
			Input.action_release("sprint")
			Input.action_release("move_forward")
			_poke_interactables(player)
		await physics_frame
	for a in ["move_forward", "sprint", "attack", "ability", "jump"]:
		Input.action_release(a)

	if not is_instance_valid(player) or not player.global_position.is_finite():
		_fail("%s/%s: player position invalid" % [biome, animal])
	else:
		var s := player.stats
		if not (is_finite(s.hunger) and is_finite(s.thirst) and is_finite(s.health) and is_finite(s.stamina) and is_finite(s.temp_offset)):
			_fail("%s/%s: stats not finite" % [biome, animal])

	_exercise_environment(level.env)
	await process_frame
	level.queue_free()
	await process_frame
	GameState.terrain = null


func _poke_interactables(player: PlayerAnimal) -> void:
	var seen: Dictionary = {}
	for n in get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null:
			continue
		var key := it.get_script().resource_path
		if seen.has(key):
			continue
		seen[key] = true
		it.get_prompt(player)
		if it.can_interact(player):
			it.interact(player)


func _exercise_environment(env: EnvironmentController) -> void:
	for w in EnvironmentController.WEATHER:
		env.weather = w
		env.intensity = 1.0
		env._configure_particles(EnvironmentController.WEATHER[w]["particles"])
		env._update_visuals()
		env._update_temperature(0.2)
		env._update_audio()
	for s in GameConst.SEASONS:
		env.season = s
		env._apply_season(false)
		env._pick_weather()
	env.hour = 23.99
	env._advance_time(1.0)
	if env.day != 1:
		_fail("day did not advance")
	print("environment ok: %s" % env.status_text())
