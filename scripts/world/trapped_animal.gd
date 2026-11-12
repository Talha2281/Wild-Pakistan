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

	if species == "indus_dolphin":
		prompt = "Rescue the stranded dolphin"
		var dv := AnimalModel.build_dolphin()
		dv.position.y = 0.3
		dv.rotation = Vector3(0.0, randf() * TAU, 0.9)
		add_child(dv)
		var pool := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 2.2
		cyl.bottom_radius = 2.2
		cyl.height = 0.05
		cyl.radial_segments = 14
		pool.mesh = cyl
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.25, 0.45, 0.5, 0.7)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pool.material_override = pm
		pool.position.y = 0.05
		add_child(pool)
		return

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
	if species == "indus_dolphin":
		_release_dolphin()
		return
	Events.game_event.emit("rescued")
	Events.toast.emit("You freed the %s!" % species.replace("_", " "))
	SaveManager.bump_stat("rescues")
	AudioManager.play_ui("chime", -6.0)
	var freed := Species.create(species)
	freed.position = position
	get_parent().add_child(freed)
	queue_free()


## The dolphin was stranded in a drying pool. Carry it back to the river.
func _release_dolphin() -> void:
	Events.game_event.emit("rescued")
	Events.toast.emit("You returned the Indus dolphin to the river! Fewer than 2,000 remain.")
	SaveManager.bump_stat("rescues")
	AudioManager.play_ui("chime", -6.0)
	var d := RiverDolphin.new()
	d.z = position.z
	d.dir = 1.0 if randf() < 0.5 else -1.0
	get_parent().add_child(d)
	queue_free()
