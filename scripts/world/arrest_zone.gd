class_name ArrestZone
extends Interactable
## Attached to every Shikari. A ranger can arrest one that has been sedated by a dart.

var shikari: ShikariAI


func _ready() -> void:
	super()
	prompt = "Arrest poacher"
	add_sphere_shape(2.4)


func can_interact(player: PlayerAnimal) -> bool:
	return shikari != null and is_instance_valid(shikari) and shikari.sedated and player.species_id == "ranger"


func interact(_player: PlayerAnimal) -> void:
	if shikari == null or not is_instance_valid(shikari):
		return
	shikari.arrest()
