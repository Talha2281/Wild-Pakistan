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

## Run score (resets each level). Orbs, eating, drinking, hunting and rescues feed a
## combo multiplier that decays if you stop collecting - the "one more run" loop.
const COMBO_TIME := 6.0
const POINTS := {"eat": 15, "drink": 10, "dig": 15, "hunt": 60, "disarm": 80, "arrest": 300, "shikari_defeated": 100, "evidence": 150, "photo_bonus": 0, "rescued": 150,
	"sabotage": 80, "chase_escaped": 100, "shikari_lost": 70, "day_survived": 200, "storm_survived": 120}
## "survive" = live as an animal, "ranger" = protect wildlife, "safari" = peaceful photography.
var mode := "survive"
var poached := 0
var fail_reason := ""
const POACH_LIMIT := 6
var score := 0
var combo := 1
var orbs := 0
var run_time := 0.0
var best_before := 0
var _combo_left := 0.0
var _next_milestone := 500
var banked_coins := 0
var _banked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	Events.game_event.connect(func(e: String) -> void:
		if POINTS.has(e):
			add_score(int(POINTS[e]), e.replace("_", " ")))


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	run_time += delta
	if _combo_left > 0.0:
		_combo_left -= delta
		if _combo_left <= 0.0 and combo > 1:
			combo = 1
			Events.score_changed.emit(score, combo)


func reset_run() -> void:
	score = 0
	combo = 1
	orbs = 0
	run_time = 0.0
	_combo_left = 0.0
	_next_milestone = 500
	_banked = false
	banked_coins = 0
	poached = 0
	fail_reason = ""
	best_before = int(SaveManager.data["stats"].get("best_score", 0))
	Events.score_changed.emit(score, combo)


func add_score(points: int, label := "") -> void:
	var gained := points * combo
	score += gained
	combo = mini(combo + 1, 10)
	_combo_left = COMBO_TIME
	Events.score_changed.emit(score, combo)
	if label != "":
		Events.score_popup.emit("+%d %s" % [gained, label])
	if score >= _next_milestone:
		_next_milestone += 500
		SaveManager.add_coins(10)
		AudioManager.play_ui("combo", -2.0)
		Events.toast.emit("Score %d! Bonus +10 coins" % (_next_milestone - 500))


## Converts the run into coins and the best-score stat. Safe to call repeatedly.
func bank_run() -> int:
	if _banked:
		return 0
	_banked = true
	SaveManager.set_stat_max("best_score", score)
	Records.finish_run(mode, score)
	banked_coins = score / 25
	if banked_coins > 0:
		SaveManager.add_coins(banked_coins)
	return banked_coins


func start_game(animal: String, biome: String, play_mode := "survive") -> void:
	mode = play_mode
	animal_id = "ranger" if play_mode != "survive" else animal
	biome_id = biome
	days_survived = 0
	SaveManager.data["last_mode"] = play_mode
	if play_mode == "survive":
		SaveManager.data["last_animal"] = animal
	SaveManager.data["last_biome"] = biome
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func go_menu() -> void:
	bank_run()
	get_tree().paused = false
	terrain = null
	player = null
	for a in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "interact", "attack", "ability"]:
		Input.action_release(a)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## Ends a ranger run early (too many animals lost).
func fail_run(reason: String) -> void:
	fail_reason = reason
	if player != null and is_instance_valid(player):
		(player as PlayerAnimal).stats.take_damage(100000.0)


func reload_level() -> void:
	bank_run()
	get_tree().paused = false
	terrain = null
	player = null
	for a in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "interact", "attack", "ability"]:
		Input.action_release(a)
	get_tree().reload_current_scene()
