extends Node
## Progress saving (JSON in user://). Versioned, merged over defaults so older
## saves keep working when new fields are added.

const SAVE_PATH := "user://wild_pakistan_save.json"
const SAVE_VERSION := 2

const DEFAULT_SETTINGS := {
	"master": 1.0,
	"sfx": 1.0,
	"ambience": 0.8,
	"sensitivity": 1.0,
	"quality": 1,
	"tutorial_done": false,
}

var data: Dictionary = {}


func _init() -> void:
	data = _defaults()


func _ready() -> void:
	load_game()


func _defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"completed_missions": [],
		"mission_progress": {},
		"owned_skins": {},
		"equipped_skin": {},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"stats": {"best_days": 0, "total_days": 0, "kills": 0, "rescues": 0, "deaths": 0},
		"last_animal": "chinkara",
		"last_biome": "thar",
	}


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file.")
		return
	f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return
	for key in parsed:
		if data.has(key) and data[key] is Dictionary and parsed[key] is Dictionary:
			for sub in parsed[key]:
				data[key][sub] = parsed[key][sub]
		else:
			data[key] = parsed[key]
	data["version"] = SAVE_VERSION


func reset_progress() -> void:
	var settings: Dictionary = data["settings"]
	data = _defaults()
	data["settings"] = settings
	save_game()
	Events.coins_changed.emit(0)
	Events.missions_changed.emit()


# ------------------------------------------------------------------ settings

func setting(key: String) -> Variant:
	return data["settings"].get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	save_game()


# --------------------------------------------------------------------- coins

func coins() -> int:
	return int(data.get("coins", 0))


func add_coins(amount: int) -> void:
	data["coins"] = coins() + amount
	Events.coins_changed.emit(coins())
	save_game()


func spend_coins(amount: int) -> bool:
	if coins() < amount:
		return false
	data["coins"] = coins() - amount
	Events.coins_changed.emit(coins())
	save_game()
	return true


# --------------------------------------------------------------------- skins

func owns_skin(animal: String, index: int) -> bool:
	if index == 0:
		return true
	var owned: Array = data["owned_skins"].get(animal, [])
	return owned.has(index)


func buy_skin(animal: String, index: int, price: int) -> bool:
	if owns_skin(animal, index):
		return true
	if not spend_coins(price):
		return false
	var owned: Array = data["owned_skins"].get(animal, [])
	owned.append(index)
	data["owned_skins"][animal] = owned
	save_game()
	return true


func equipped_skin(animal: String) -> int:
	return int(data["equipped_skin"].get(animal, 0))


func equip_skin(animal: String, index: int) -> void:
	if owns_skin(animal, index):
		data["equipped_skin"][animal] = index
		save_game()


# ------------------------------------------------------------------ progress

func completed_count() -> int:
	return (data["completed_missions"] as Array).size()


func bump_stat(key: String, amount := 1) -> void:
	var stats: Dictionary = data["stats"]
	stats[key] = int(stats.get(key, 0)) + amount
	save_game()


func set_stat_max(key: String, value: int) -> void:
	var stats: Dictionary = data["stats"]
	if value > int(stats.get(key, 0)):
		stats[key] = value
		save_game()


func animal_unlocked(id: String) -> bool:
	return completed_count() >= int(Animals.DB[id]["unlock_missions"])


func biome_unlocked(id: String) -> bool:
	return completed_count() >= int(Biomes.DB[id]["unlock_missions"])
