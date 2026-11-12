class_name Catalog
extends RefCounted
## Field-guide data for every species in the game (playable or not): conservation
## status, how hard it is to find (rarity 1-5, used to rate photographs) and a fact.
## Also the conservation lessons shown to the player.

const INFO := {
	"chinkara": {"name": "Chinkara", "status": "Vulnerable", "rarity": 3,
		"fact": "Indian gazelle of the Thar and Cholistan. Poaching and habitat loss are its main threats."},
	"markhor": {"name": "Suleiman Markhor", "status": "Near Threatened", "rarity": 4,
		"fact": "Pakistan's national animal. Community trophy-hunting programmes helped numbers recover."},
	"ibex": {"name": "Himalayan Ibex", "status": "Least Concern", "rarity": 3,
		"fact": "Lives on steep cliffs in Gilgit-Baltistan. Males carry long curved horns."},
	"blue_sheep": {"name": "Blue Sheep (Bharal)", "status": "Least Concern", "rarity": 3,
		"fact": "A main prey of the snow leopard, found in the high Himalaya and Karakoram."},
	"marmot": {"name": "Himalayan Marmot", "status": "Least Concern", "rarity": 2,
		"fact": "Hibernates in burrows for about half the year and whistles to warn of danger."},
	"hare": {"name": "Desert Hare", "status": "Least Concern", "rarity": 1,
		"fact": "Large ears release heat, and it can bolt at high speed to escape foxes."},
	"lizard": {"name": "Spiny-tailed Lizard", "status": "Vulnerable", "rarity": 2,
		"fact": "A Thar burrow-dweller. It is collected illegally for the pet and medicine trade."},
	"desert_fox": {"name": "Desert Fox", "status": "Least Concern", "rarity": 2,
		"fact": "Large ears keep it cool. It hunts at night and rarely needs to drink."},
	"red_fox": {"name": "Red Fox", "status": "Least Concern", "rarity": 1,
		"fact": "A clever hunter found in forests and mountains across Pakistan."},
	"black_bear": {"name": "Balochistan Black Bear", "status": "Vulnerable", "rarity": 3,
		"fact": "A small, shy bear of the Balochistan hills. Conflict with villagers threatens it."},
	"snow_leopard": {"name": "Snow Leopard", "status": "Vulnerable", "rarity": 5,
		"fact": "The ghost of the mountains. Fewer than about 400 live in Pakistan."},
	"brown_bear": {"name": "Himalayan Brown Bear", "status": "Critically Endangered (Pakistan)", "rarity": 5,
		"fact": "Survives mainly on the Deosai Plateau. Only a few dozen remain in Pakistan."},
	"indus_dolphin": {"name": "Indus River Dolphin", "status": "Endangered", "rarity": 5,
		"fact": "A nearly blind freshwater dolphin found only in the Indus. It hunts with sound, and dams and pollution threaten it."},
	"wild_boar": {"name": "Wild Boar", "status": "Least Concern", "rarity": 1,
		"fact": "Common across Pakistan's forests and river belts. It helps the soil by digging."},
	"jackal": {"name": "Golden Jackal", "status": "Least Concern", "rarity": 1,
		"fact": "A clever scavenger that calls in groups at dusk."},
	"striped_hyena": {"name": "Striped Hyena", "status": "Near Threatened", "rarity": 3,
		"fact": "A shy night scavenger that cleans up carcasses and keeps disease from spreading."},
	"urial": {"name": "Punjab Urial", "status": "Vulnerable", "rarity": 3,
		"fact": "A wild sheep of the Salt Range and northern hills with a curling horn."},
	"marco_polo": {"name": "Marco Polo Sheep", "status": "Near Threatened", "rarity": 4,
		"fact": "Has the longest horns of any sheep and lives on the high Pamir plateau."},
	"musk_deer": {"name": "Kashmir Musk Deer", "status": "Endangered", "rarity": 5,
		"fact": "A shy forest deer hunted illegally for its scent gland."},
}

const LESSONS := [
	"Poaching and illegal trade have pushed many Pakistani species towards extinction.",
	"Fewer than about 400 snow leopards live in Pakistan. Every animal counts.",
	"The Indus river dolphin survives only in the Indus. Dams and pollution cut its home into pieces.",
	"Snares kill silently and indiscriminately. Reporting and removing them saves many animals.",
	"Community conservancies turned markhor hunters into protectors, and the markhor came back.",
	"Healthy predators keep prey herds strong. Losing a top predator damages the whole ecosystem.",
	"Rangers, villagers and visitors all play a role. Report wildlife crime to the local wildlife department.",
	"Never buy wildlife products such as skins, horns or pets. Demand fuels poaching.",
	"Clean rivers and forests protect wildlife and the people who depend on them.",
	"Climate change is melting the glaciers that feed Pakistan's rivers and mountain ecosystems.",
]


static func info(id: String) -> Dictionary:
	if INFO.has(id):
		return INFO[id]
	return {"name": id.capitalize().replace("_", " "), "status": "Unknown", "rarity": 1, "fact": ""}


static func species_name(id: String) -> String:
	return String(info(id)["name"])


static func rarity(id: String) -> int:
	return int(info(id)["rarity"])


static func random_lesson() -> String:
	return String(LESSONS[randi() % LESSONS.size()])


static func total_species() -> int:
	return INFO.size()
