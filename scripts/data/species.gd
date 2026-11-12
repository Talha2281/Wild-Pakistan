class_name Species
extends RefCounted
## NPC wildlife table. Add a row to add an animal to the ecosystem.
##
## predator:   scares prey, appears in the "predators" group
## diet:       herbivore / omnivore / carnivore (herbivores and omnivores graze plants)
## hunts:      species ids this animal will chase and kill
## threat_to:  playable animal ids this animal will attack on sight
## territorial: radius within which it charges the player (0 = never)
## climb:      steepest slope (degrees) it can walk
## hp:         hits to kill (player attack_dmg is subtracted)
## herd:       alarms nearby animals of the same species when it flees

const DB := {
	"chinkara": {
		"predator": false, "diet": "herbivore", "hp": 3.0, "walk": 2.2, "run": 9.5,
		"vision": 26.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 46.0, "herd": true, "alert": "snort", "meat": 45.0,
	},
	"markhor": {
		"predator": false, "diet": "herbivore", "hp": 5.0, "walk": 2.0, "run": 8.5,
		"vision": 30.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 78.0, "herd": true, "alert": "bleat", "meat": 60.0,
	},
	"ibex": {
		"predator": false, "diet": "herbivore", "hp": 4.0, "walk": 2.0, "run": 9.0,
		"vision": 30.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 80.0, "herd": true, "alert": "bleat", "meat": 55.0,
	},
	"blue_sheep": {
		"predator": false, "diet": "herbivore", "hp": 4.0, "walk": 2.0, "run": 8.5,
		"vision": 28.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 72.0, "herd": true, "alert": "bleat", "meat": 55.0,
	},
	"marmot": {
		"predator": false, "diet": "herbivore", "hp": 1.0, "walk": 1.0, "run": 5.5,
		"vision": 20.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 50.0, "herd": false, "alert": "whistle", "meat": 30.0,
	},
	"hare": {
		"predator": false, "diet": "herbivore", "hp": 1.0, "walk": 1.4, "run": 11.0,
		"vision": 22.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 50.0, "herd": false, "alert": "", "meat": 28.0,
	},
	"lizard": {
		"predator": false, "diet": "herbivore", "hp": 1.0, "walk": 0.9, "run": 4.2,
		"vision": 12.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 45.0, "herd": false, "alert": "", "meat": 18.0,
	},
	"desert_fox": {
		"predator": true, "diet": "carnivore", "hp": 3.0, "walk": 2.6, "run": 8.8,
		"vision": 28.0, "hunts": ["lizard", "hare"], "threat_to": ["chinkara"], "territorial": 0.0,
		"climb": 50.0, "herd": false, "alert": "fox_bark", "meat": 30.0,
	},
	"red_fox": {
		"predator": true, "diet": "carnivore", "hp": 3.0, "walk": 2.6, "run": 9.0,
		"vision": 30.0, "hunts": ["hare", "marmot"], "threat_to": ["chinkara"], "territorial": 0.0,
		"climb": 55.0, "herd": false, "alert": "fox_bark", "meat": 30.0,
	},
	"black_bear": {
		"predator": true, "diet": "omnivore", "hp": 9.0, "walk": 2.2, "run": 7.8,
		"vision": 20.0, "hunts": ["hare", "marmot"], "threat_to": [], "territorial": 9.0,
		"climb": 52.0, "herd": false, "alert": "bear_growl", "meat": 80.0,
	},
	"snow_leopard": {
		"predator": true, "diet": "carnivore", "hp": 6.0, "walk": 2.8, "run": 12.5,
		"vision": 36.0, "hunts": ["ibex", "blue_sheep", "marmot", "hare"], "threat_to": ["markhor", "chinkara"],
		"territorial": 0.0, "climb": 72.0, "herd": false, "alert": "leopard_growl", "meat": 80.0,
	},
	"brown_bear": {
		"predator": true, "diet": "omnivore", "hp": 14.0, "walk": 2.2, "run": 8.0,
		"vision": 22.0, "hunts": ["marmot"], "threat_to": [], "territorial": 10.0,
		"climb": 50.0, "herd": false, "alert": "bear_growl", "meat": 100.0,
	},
	"wild_boar": {
		"predator": false, "diet": "omnivore", "hp": 6.0, "walk": 2.0, "run": 8.0,
		"vision": 16.0, "hunts": [], "threat_to": [], "territorial": 6.0,
		"climb": 48.0, "herd": true, "alert": "bear_growl", "meat": 70.0,
	},
	"jackal": {
		"predator": true, "diet": "carnivore", "hp": 3.0, "walk": 2.6, "run": 9.2,
		"vision": 28.0, "hunts": ["hare", "lizard", "marmot"], "threat_to": ["chinkara"], "territorial": 0.0,
		"climb": 52.0, "herd": false, "alert": "howl", "meat": 30.0,
	},
	"striped_hyena": {
		"predator": true, "diet": "carnivore", "hp": 6.0, "walk": 2.4, "run": 9.5,
		"vision": 30.0, "hunts": ["hare", "jackal"], "threat_to": ["chinkara"], "territorial": 0.0,
		"climb": 55.0, "herd": false, "alert": "howl", "meat": 60.0,
	},
	"urial": {
		"predator": false, "diet": "herbivore", "hp": 4.0, "walk": 2.0, "run": 9.0,
		"vision": 30.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 70.0, "herd": true, "alert": "bleat", "meat": 55.0,
	},
	"marco_polo": {
		"predator": false, "diet": "herbivore", "hp": 5.0, "walk": 2.0, "run": 8.5,
		"vision": 32.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 65.0, "herd": true, "alert": "bleat", "meat": 65.0,
	},
	"musk_deer": {
		"predator": false, "diet": "herbivore", "hp": 2.0, "walk": 1.8, "run": 10.0,
		"vision": 24.0, "hunts": [], "threat_to": [], "territorial": 0.0,
		"climb": 70.0, "herd": false, "alert": "snort", "meat": 30.0,
	},
}


static func create(id: String) -> WildlifeAI:
	var cfg: Dictionary = DB[id]
	var a := WildlifeAI.new()
	a.species = id
	a.predator = cfg["predator"]
	a.diet = cfg["diet"]
	a.hp = cfg["hp"]
	a.walk_speed = cfg["walk"]
	a.run_speed = cfg["run"]
	a.vision_range = cfg["vision"]
	a.hunts = PackedStringArray(cfg["hunts"])
	a.threat_to = PackedStringArray(cfg["threat_to"])
	a.territorial_radius = cfg["territorial"]
	a.climb_angle = cfg["climb"]
	a.herd = cfg["herd"]
	a.alert_sound = cfg["alert"]
	a.meat_value = cfg["meat"]
	return a
