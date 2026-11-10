class_name TrappedAnimal
extends Interactable
## A snared animal to rescue (conservation mission). Freeing it spawns a normal
## wandering animal of the same species in its place.

@export var species := "chinkara"


func _ready() -> void:
	super()
	prompt = "Free the %s" % species.replace("_", " ")
	add_to_group("trapped")
	add_sphere_shape(1.6)

	var v := AnimalModel.build(species)
	v.rotation.y = randf() * TAU
	add_child(v)

	var rope := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.05
	torus.rings = 8
	torus.ring_segments = 6
	rope.mesh = torus
	rope.material_override = PlaceholderModel.material(Color(0.5, 0.35, 0.2))
	rope.scale = Vector3(1.0, 0.4, 1.0)
	rope.position.y = 0.06
	add_child(rope)


func interact(_player: PlayerAnimal) -> void:
	Events.game_event.emit("rescued")
	Events.toast.emit("You freed the %s!" % species.replace("_", " "))
	SaveManager.bump_stat("rescues")
	AudioManager.play_ui("chime", -6.0)
	var freed := Species.create(species)
	freed.position = position
	get_parent().add_child(freed)
	queue_free()
