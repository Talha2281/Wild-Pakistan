class_name NatureAmbience
extends Node
## Random natural sounds around the player: birdsong by day, crickets, owls and
## frogs by night, eagles and wind over the mountains, splashes at the river.
## Each biome has its own cast so every habitat sounds different.

const DAY := {
	"thar": ["chirp_a", "cuckoo", "crow", "chirp_b", "chirp_a"],
	"indus": ["chirp_a", "chirp_b", "frog", "splash", "eagle", "chirp_a"],
	"ziarat": ["chirp_b", "cuckoo", "chirp_a", "crow", "chirp_b"],
	"deosai": ["eagle", "chirp_b", "whistle", "chirp_a"],
	"northern": ["eagle", "crow", "whistle"],
}
const NIGHT := {
	"thar": ["cricket", "howl", "owl", "cricket"],
	"indus": ["frog", "cricket", "owl", "frog", "howl"],
	"ziarat": ["owl", "cricket", "howl", "owl"],
	"deosai": ["howl", "owl", "whistle"],
	"northern": ["howl", "owl"],
}

var _timer := 2.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(1.8, 5.5)
	var pl := GameState.player as Node3D
	if pl == null or not is_instance_valid(pl):
		return
	var pool: Dictionary = NIGHT if GameState.is_night else DAY
	var list: Array = pool.get(GameState.biome_id, pool["thar"])
	var sound: String = list[randi() % list.size()]
	var ang := randf() * TAU
	var dist := randf_range(8.0, 34.0)
	var pos := pl.global_position + Vector3(cos(ang) * dist, randf_range(0.5, 6.0), sin(ang) * dist)
	AudioManager.play_3d(sound, pos, randf_range(-6.0, 0.0), 0.12)
