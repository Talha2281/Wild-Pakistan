class_name CampGear
extends Interactable
## Poacher supplies (crates, nets, lanterns). Wrecking them counts toward sabotage
## missions but makes a loud crash that nearby Shikari will hear.

var wrecked := false

static var _mesh: Mesh

var _visual: MeshInstance3D


func _ready() -> void:
	super()
	prompt = "Wreck poacher gear"
	add_to_group("camp_gear")
	add_sphere_shape(1.4)
	if _mesh == null:
		var st := MeshBuilder.start()
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.4, 0.0), Vector3(0.0, 15.0, 0.0)), Vector3(1.1, 0.8, 0.8), Color(0.45, 0.3, 0.16))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.7, 0.28, 0.2), Vector3(0.0, -20.0, 0.0)), Vector3(0.7, 0.56, 0.6), Color(0.38, 0.26, 0.14))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.84, 0.0), Vector3(0.0, 15.0, 0.0)), Vector3(1.15, 0.08, 0.85), Color(0.6, 0.15, 0.12))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(-0.2, 0.98, 0.1), Vector3(0.0, 40.0, 0.0)), Vector3(0.3, 0.2, 0.3), Color(0.55, 0.5, 0.3))
		_mesh = MeshBuilder.finish(st)
	_visual = MeshBuilder.instance(_mesh)
	add_child(_visual)


func can_interact(_player: PlayerAnimal) -> bool:
	return not wrecked


func interact(player: PlayerAnimal) -> void:
	wrecked = true
	_visual.rotation_degrees = Vector3(18.0, 0.0, 70.0)
	_visual.position.y = 0.1
	player.make_noise(1.4, 4.0)
	AudioManager.play_3d("trap_snap", global_position, 3.0)
	Events.toast.emit("Gear wrecked! The noise will draw attention.")
	Events.game_event.emit("sabotage")
