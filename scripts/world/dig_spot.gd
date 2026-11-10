class_name DigSpot
extends Interactable
## Loose earth hiding roots, grubs and burrows. Only bears can dig it up.

var available := true
var _mound: MeshInstance3D

static var _mesh: Mesh


func _ready() -> void:
	super()
	prompt = "Dig"
	add_sphere_shape(1.1)
	if _mesh == null:
		var st := MeshBuilder.start()
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.12, 0.0), Vector3(0.0, 20.0, 0.0)), Vector3(0.9, 0.24, 0.8), Color(0.32, 0.22, 0.15))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.2, 0.26, 0.1), Vector3(0.0, 50.0, 0.0)), Vector3(0.45, 0.18, 0.4), Color(0.38, 0.27, 0.18))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(-0.5, 0.06, 0.3)), Vector3(0.18, 0.12, 0.16), Color(0.5, 0.48, 0.45))
		_mesh = MeshBuilder.finish(st)
	_mound = MeshBuilder.instance(_mesh)
	add_child(_mound)
	# Only bears notice the mound; for everyone else it is just scenery.
	if not Animals.DIGGERS.has(GameState.animal_id):
		monitorable = false


func can_interact(player: PlayerAnimal) -> bool:
	return available and Animals.DIGGERS.has(player.species_id)


func interact(player: PlayerAnimal) -> void:
	available = false
	_mound.scale = Vector3(1.0, 0.4, 1.0)
	player.stats.eat(35.0)
	player.look_down(1.6)
	AudioManager.play_3d("dig", global_position)
	Events.game_event.emit("dig")
	get_tree().create_timer(120.0).timeout.connect(_refill)


func _refill() -> void:
	available = true
	_mound.scale = Vector3.ONE
