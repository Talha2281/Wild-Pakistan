extends Node
## Shared run state: what the player picked, plus world values that AI and
## survival code read every frame (weather visibility, ambient temperature, ...).

var animal_id := "chinkara"
var biome_id := "thar"

## Set by the level once the terrain exists.
var terrain: BiomeTerrain = null
var half_size := 96.0
var step_sound := "step_sand"

## Written by EnvironmentController.
var visibility_mult := 1.0
var ambient_temp := 25.0
var track_life_mult := 1.0
var is_night := false
var weather := "clear"
var season := "summer"
var days_survived := 0

var player: Node3D = null


func start_game(animal: String, biome: String) -> void:
	animal_id = animal
	biome_id = biome
	days_survived = 0
	SaveManager.data["last_animal"] = animal
	SaveManager.data["last_biome"] = biome
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_menu() -> void:
	get_tree().paused = false
	terrain = null
	player = null
	for a in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "interact", "attack", "ability"]:
		Input.action_release(a)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func reload_level() -> void:
	get_tree().paused = false
	terrain = null
	player = null
	for a in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "interact", "attack", "ability"]:
		Input.action_release(a)
	get_tree().reload_current_scene()
