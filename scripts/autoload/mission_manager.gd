extends Node
## Data-driven missions. To add one: append a dictionary to MISSIONS and emit the
## matching Events.game_event(...) from gameplay code.
##
## Fields:
##  biome      biome id, or "any"
##  event      the game_event name that advances it
##  diets      optional: only offered to these diets (herbivore/omnivore/carnivore)
##  animals    optional: only offered to these playable animal ids
##  min_climb  optional: only offered to animals that can climb at least this steep

const MISSIONS := [
	# ---- Thar Desert
	{"id": "thar_drink", "biome": "thar", "title": "Quench Your Thirst", "event": "drink", "target": 3, "reward": 20},
	{"id": "thar_forage", "biome": "thar", "title": "Desert Forager", "event": "eat", "target": 5, "reward": 30, "diets": ["herbivore", "omnivore"]},
	{"id": "thar_escape", "biome": "thar", "title": "Outrun the Fox", "event": "chase_escaped", "target": 1, "reward": 40},
	{"id": "thar_ghost", "biome": "thar", "title": "Ghost of the Dunes", "event": "shikari_lost", "target": 1, "reward": 50},
	{"id": "thar_rescue", "biome": "thar", "title": "Freed From the Snare", "event": "rescued", "target": 1, "reward": 60},
	{"id": "thar_disarm", "biome": "thar", "title": "Snare Sweeper", "event": "disarm", "target": 3, "reward": 50},
	{"id": "thar_sandstorm", "biome": "thar", "title": "Dust and Wind", "event": "storm_survived", "target": 1, "reward": 60},
	{"id": "thar_wreck", "biome": "thar", "title": "Spoil the Hunt", "event": "sabotage", "target": 2, "reward": 40},
	# ---- Ziarat Juniper Forest
	{"id": "zi_drink", "biome": "ziarat", "title": "Mountain Spring", "event": "drink", "target": 4, "reward": 25},
	{"id": "zi_forage", "biome": "ziarat", "title": "Juniper Grazer", "event": "eat", "target": 6, "reward": 35, "diets": ["herbivore", "omnivore"]},
	{"id": "zi_hunt", "biome": "ziarat", "title": "Forest Hunter", "event": "hunt", "target": 2, "reward": 50, "diets": ["carnivore", "omnivore"]},
	{"id": "zi_lookout", "biome": "ziarat", "title": "Ridge Lookout", "event": "lookout", "target": 1, "reward": 50},
	{"id": "zi_rescue", "biome": "ziarat", "title": "Cut the Wires", "event": "rescued", "target": 2, "reward": 80},
	{"id": "zi_disarm", "biome": "ziarat", "title": "Clear the Trapline", "event": "disarm", "target": 4, "reward": 60},
	{"id": "zi_ghost", "biome": "ziarat", "title": "Shadow in the Junipers", "event": "shikari_lost", "target": 2, "reward": 70},
	{"id": "zi_wreck", "biome": "ziarat", "title": "Raid the Camp", "event": "sabotage", "target": 3, "reward": 60},
	{"id": "zi_storm", "biome": "ziarat", "title": "Weather the Storm", "event": "storm_survived", "target": 1, "reward": 60},
	# ---- Northern Mountains
	{"id": "no_drink", "biome": "northern", "title": "Meltwater", "event": "drink", "target": 3, "reward": 25},
	{"id": "no_forage", "biome": "northern", "title": "Alpine Grazer", "event": "eat", "target": 6, "reward": 40, "diets": ["herbivore", "omnivore"]},
	{"id": "no_hunt", "biome": "northern", "title": "Apex Predator", "event": "hunt", "target": 3, "reward": 70, "diets": ["carnivore", "omnivore"]},
	{"id": "no_dig", "biome": "northern", "title": "Root and Burrow", "event": "dig", "target": 3, "reward": 60, "animals": ["brown_bear"]},
	{"id": "no_summit", "biome": "northern", "title": "Roof of the World", "event": "summit", "target": 2, "reward": 100, "min_climb": 70.0},
	{"id": "no_rescue", "biome": "northern", "title": "Free the Mountain", "event": "rescued", "target": 2, "reward": 100},
	{"id": "no_ghost", "biome": "northern", "title": "Whiteout Escape", "event": "shikari_lost", "target": 3, "reward": 90},
	{"id": "no_disarm", "biome": "northern", "title": "Snow Trapline", "event": "disarm", "target": 4, "reward": 70},
	{"id": "no_blizzard", "biome": "northern", "title": "Survive the Blizzard", "event": "storm_survived", "target": 1, "reward": 80},
	{"id": "no_wreck", "biome": "northern", "title": "Break the Poachers", "event": "sabotage", "target": 3, "reward": 70},
	# ---- Anywhere
	{"id": "g_days3", "biome": "any", "title": "Survivor (3 days)", "event": "day_survived", "target": 3, "reward": 80},
	{"id": "g_days10", "biome": "any", "title": "Seasoned Survivor (10 days)", "event": "day_survived", "target": 10, "reward": 250},
]

var progress: Dictionary = {}
var completed: Array = []


func _ready() -> void:
	var saved: Dictionary = SaveManager.data.get("mission_progress", {})
	for m in MISSIONS:
		progress[m["id"]] = int(saved.get(m["id"], 0))
	completed = SaveManager.data.get("completed_missions", []).duplicate()
	Events.game_event.connect(_on_game_event)


## Missions offered for the current animal and biome.
func active_missions() -> Array:
	var out: Array = []
	for m in MISSIONS:
		if _offered(m, GameState.biome_id, GameState.animal_id):
			out.append(m)
	return out


func missions_for_biome(biome: String) -> Array:
	var out: Array = []
	for m in MISSIONS:
		if m["biome"] == biome:
			out.append(m)
	return out


func _offered(m: Dictionary, biome: String, animal: String) -> bool:
	if m["biome"] != "any" and m["biome"] != biome:
		return false
	var cfg: Dictionary = Animals.DB[animal]
	if m.has("diets") and not (m["diets"] as Array).has(cfg["diet"]):
		return false
	if m.has("animals") and not (m["animals"] as Array).has(animal):
		return false
	if m.has("min_climb") and float(cfg["climb_angle"]) < float(m["min_climb"]):
		return false
	return true


func _on_game_event(event_name: String) -> void:
	var changed := false
	for m in active_missions():
		if m["event"] != event_name or completed.has(m["id"]):
			continue
		progress[m["id"]] += 1
		changed = true
		if progress[m["id"]] >= m["target"]:
			_complete(m)
	if changed:
		SaveManager.data["mission_progress"] = progress
		SaveManager.data["completed_missions"] = completed
		SaveManager.save_game()
		Events.missions_changed.emit()


func _complete(m: Dictionary) -> void:
	var before_animals := _unlocked_animals()
	var before_biomes := _unlocked_biomes()
	completed.append(m["id"])
	SaveManager.data["completed_missions"] = completed
	Events.toast.emit("Mission complete: %s  (+%d coins)" % [m["title"], m["reward"]])
	SaveManager.add_coins(m["reward"])
	for id in _unlocked_animals():
		if not before_animals.has(id):
			Events.toast.emit("New animal unlocked: %s!" % Animals.DB[id]["name"])
			Events.unlocked.emit(id)
	for id in _unlocked_biomes():
		if not before_biomes.has(id):
			Events.toast.emit("New habitat unlocked: %s!" % Biomes.DB[id]["name"])
			Events.unlocked.emit(id)


func _unlocked_animals() -> Array:
	var out: Array = []
	for id in Animals.ORDER:
		if SaveManager.animal_unlocked(id):
			out.append(id)
	return out


func _unlocked_biomes() -> Array:
	var out: Array = []
	for id in Biomes.ORDER:
		if SaveManager.biome_unlocked(id):
			out.append(id)
	return out


## Lines for the HUD panel.
func get_lines() -> Array[String]:
	var lines: Array[String] = []
	for m in active_missions():
		var done: bool = completed.has(m["id"])
		var mark := "[x]" if done else "[ ]"
		var count := ""
		if not done and m["target"] > 1:
			count = "  %d/%d" % [progress[m["id"]], m["target"]]
		lines.append("%s %s%s" % [mark, m["title"], count])
	return lines
