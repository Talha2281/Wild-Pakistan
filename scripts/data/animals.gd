class_name Animals
extends RefCounted
## Playable animals. Stats, abilities, unlock rules, skins and short wildlife facts.
## Model shapes live in AnimalModel.SPECS (same ids).
##
## ability:  "burst" (speed boost), "leap" (long cliff jump), "stealth" (toggle crouch),
##           "roar" (scares nearby animals and Shikari)
## attack:   "kick", "charge", "pounce", "swipe"
## comfort:  [min, max] ambient C where the animal feels fine

const ORDER := ["chinkara", "markhor", "snow_leopard", "brown_bear"]

const SKIN_PRICES := [0, 150, 300]

## Animals that can dig up DigSpot mounds.
const DIGGERS := ["brown_bear"]

const DB := {
	"chinkara": {
		"name": "Chinkara", "latin": "Gazella bennettii", "status": "Vulnerable (IUCN)",
		"diet": "herbivore", "predator": false,
		"habitats": ["thar", "indus", "ziarat"], "unlock_missions": 0,
		"max_health": 90.0, "walk": 5.0, "run": 11.5, "jump": 6.8,
		"stamina_drain": 17.0, "hunger_rate": 0.55, "thirst_rate": 0.75,
		"comfort": [6.0, 40.0], "climb_angle": 46.0,
		"ability": "burst", "ability_name": "Burst", "ability_cd": 10.0, "ability_time": 2.5,
		"ability_desc": "A short, explosive sprint that costs no stamina.",
		"attack": "kick", "attack_name": "Kick", "attack_dmg": 1.0, "attack_range": 2.3,
		"attack_cd": 1.0, "stun": 0.0,
		"desc": "Fast and light. Outrun foxes, hide in scrub, and graze desert shrubs.",
		"fact": "The chinkara, or Indian gazelle, is a desert specialist that can go long periods without drinking. Habitat loss and hunting have made it Vulnerable.",
		"skins": [
			{"name": "Desert Sand", "color": Color(0.74, 0.54, 0.34)},
			{"name": "Dusk Roan", "color": Color(0.58, 0.4, 0.28)},
			{"name": "Pale Dune", "color": Color(0.88, 0.76, 0.58)},
		],
	},
	"markhor": {
		"name": "Suleiman Markhor", "latin": "Capra falconeri jerdoni", "status": "Near Threatened (species)",
		"diet": "herbivore", "predator": false,
		"habitats": ["ziarat", "deosai", "northern"], "unlock_missions": 3,
		"max_health": 110.0, "walk": 4.6, "run": 9.5, "jump": 7.2,
		"stamina_drain": 15.0, "hunger_rate": 0.5, "thirst_rate": 0.55,
		"comfort": [-14.0, 30.0], "climb_angle": 78.0,
		"ability": "leap", "ability_name": "Cliff Leap", "ability_cd": 6.0, "ability_time": 0.0,
		"ability_desc": "A powerful forward leap for crossing ledges and steep rock.",
		"attack": "charge", "attack_name": "Horn Charge", "attack_dmg": 2.0, "attack_range": 3.2,
		"attack_cd": 1.6, "stun": 2.5,
		"desc": "A sure-footed mountain climber. Scale slopes others cannot, and stun threats with your horns.",
		"fact": "The markhor is Pakistan's national animal, famed for its corkscrew horns. Community-run conservation has helped its numbers recover.",
		"skins": [
			{"name": "Slate Grey", "color": Color(0.62, 0.58, 0.52)},
			{"name": "Winter Cream", "color": Color(0.86, 0.82, 0.74)},
			{"name": "Rust Coat", "color": Color(0.55, 0.38, 0.28)},
		],
	},
	"snow_leopard": {
		"name": "Snow Leopard", "latin": "Panthera uncia", "status": "Vulnerable (IUCN)",
		"diet": "carnivore", "predator": true,
		"habitats": ["northern", "deosai"], "unlock_missions": 8,
		"max_health": 100.0, "walk": 5.4, "run": 12.5, "jump": 8.2,
		"stamina_drain": 20.0, "hunger_rate": 0.7, "thirst_rate": 0.5,
		"comfort": [-36.0, 24.0], "climb_angle": 72.0,
		"ability": "stealth", "ability_name": "Stalk", "ability_cd": 0.0, "ability_time": 0.0,
		"ability_desc": "Toggle a low crawl: very quiet and hard to spot. Prey won't notice you until you are close.",
		"attack": "pounce", "attack_name": "Pounce", "attack_dmg": 3.0, "attack_range": 5.0,
		"attack_cd": 2.0, "stun": 0.0,
		"desc": "The ghost of the mountains. Stalk prey, pounce, and feed on what you catch.",
		"fact": "Snow leopards live across the high mountains of Gilgit-Baltistan. Their thick tail helps them balance and keeps their face warm in the cold.",
		"skins": [
			{"name": "Mountain Grey", "color": Color(0.78, 0.78, 0.76)},
			{"name": "Dark Rosette", "color": Color(0.6, 0.6, 0.6)},
			{"name": "Frost White", "color": Color(0.94, 0.95, 0.96)},
		],
	},
	"brown_bear": {
		"name": "Himalayan Brown Bear", "latin": "Ursus arctos isabellinus", "status": "Critically endangered in Pakistan",
		"diet": "omnivore", "predator": true,
		"habitats": ["northern", "ziarat", "deosai"], "unlock_missions": 12,
		"max_health": 160.0, "walk": 4.2, "run": 9.0, "jump": 5.2,
		"stamina_drain": 22.0, "hunger_rate": 0.6, "thirst_rate": 0.6,
		"comfort": [-30.0, 28.0], "climb_angle": 50.0,
		"ability": "roar", "ability_name": "Roar", "ability_cd": 18.0, "ability_time": 0.0,
		"ability_desc": "A thunderous roar that scares nearby animals and Shikari.",
		"attack": "swipe", "attack_name": "Swipe", "attack_dmg": 3.0, "attack_range": 3.2,
		"attack_cd": 1.5, "stun": 3.0,
		"desc": "Strong and tough. Dig for roots and marmots, forage, and drive enemies off with a roar.",
		"fact": "In Pakistan the Himalayan brown bear survives mainly on the high plateau of Deosai. Its population there is very small and needs protection.",
		"skins": [
			{"name": "Sandy Brown", "color": Color(0.5, 0.36, 0.24)},
			{"name": "Dark Chestnut", "color": Color(0.32, 0.22, 0.16)},
			{"name": "Silver Tip", "color": Color(0.62, 0.55, 0.46)},
		],
	},
}


## Not part of ORDER: chosen through the Ranger and Safari modes.
const RANGER := {
	"name": "Wildlife Ranger", "latin": "Homo sapiens", "status": "Protector of the wild",
	"diet": "human", "predator": false, "human": true, "photographer": true,
	"habitats": ["thar", "indus", "ziarat", "deosai", "northern"], "unlock_missions": 0,
	"max_health": 120.0, "walk": 4.6, "run": 8.6, "jump": 5.6,
	"stamina_drain": 14.0, "hunger_rate": 0.18, "thirst_rate": 0.4,
	"comfort": [-12.0, 36.0], "climb_angle": 50.0,
	"ability": "burst", "ability_name": "Sprint", "ability_cd": 12.0, "ability_time": 2.5,
	"ability_desc": "A short burst of speed to catch poachers.",
	"attack": "tranq", "attack_name": "Dart", "attack_dmg": 0.0, "attack_range": 24.0,
	"attack_cd": 1.3, "stun": 9.0,
	"desc": "Protect wildlife: tranquilise poachers and arrest them, free trapped animals, remove snares, and photograph rare species.",
	"fact": "Rangers and wildlife departments are the front line of conservation in Pakistan.",
	"skins": [
		{"name": "Forest Green", "color": Color(0.2, 0.42, 0.26)},
		{"name": "Desert Khaki", "color": Color(0.62, 0.55, 0.38)},
		{"name": "Snow Patrol", "color": Color(0.82, 0.84, 0.88)},
	],
}


static func get_cfg(id: String) -> Dictionary:
	return RANGER if id == "ranger" else DB[id]


static func skin_color(id: String, index: int) -> Color:
	var skins: Array = get_cfg(id)["skins"]
	return skins[clampi(index, 0, skins.size() - 1)]["color"]
