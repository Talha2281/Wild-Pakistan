class_name FoodPlant
extends Interactable
## Edible plant. Regrows after being eaten (slower in winter). Carnivores can't eat it.
## kind: shrub (desert), shoot (juniper forest), alpine (mountain pasture)

@export var kind := "shrub"
@export var regrow_seconds := 60.0

static var _meshes: Dictionary = {}

var available := true
var _visual: MeshInstance3D


func _ready() -> void:
	super()
	prompt = "Eat"
	add_to_group("food_plants")
	add_sphere_shape(0.9)
	_visual = MeshBuilder.instance(_mesh_for(kind))
	_visual.rotation.y = randf() * TAU
	add_child(_visual)


func can_interact(player: PlayerAnimal) -> bool:
	return available and player.diet != "carnivore"


func interact(player: PlayerAnimal) -> void:
	player.stats.eat(30.0)
	player.look_down(1.4)
	AudioManager.play_3d("eat", global_position)
	Events.game_event.emit("eat")
	_consume()


func npc_consume() -> void:
	_consume()


func _consume() -> void:
	if not available:
		return
	available = false
	_visual.visible = false
	var wait := regrow_seconds * (2.0 if GameState.season == "winter" else 1.0)
	get_tree().create_timer(wait).timeout.connect(_regrow)


func _regrow() -> void:
	available = true
	_visual.visible = true


static func _mesh_for(plant_kind: String) -> Mesh:
	if _meshes.has(plant_kind):
		return _meshes[plant_kind]
	var st := MeshBuilder.start()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(plant_kind)
	var leaf := Color(0.42, 0.55, 0.25)
	var fruit := Color(0.85, 0.3, 0.15)
	match plant_kind:
		"shoot":
			leaf = Color(0.28, 0.45, 0.25)
			fruit = Color(0.25, 0.3, 0.6)
		"alpine":
			leaf = Color(0.5, 0.58, 0.4)
			fruit = Color(0.95, 0.95, 0.8)
	for i in 6:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.3)
		var s := rng.randf_range(0.28, 0.5)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * d, s * 0.45, sin(a) * d), Vector3(rng.randf_range(-20.0, 20.0), rng.randf_range(0.0, 90.0), rng.randf_range(-20.0, 20.0))), Vector3(s, s * 0.9, s), leaf.lightened(rng.randf_range(-0.1, 0.12)))
	for i in 3:
		var a := rng.randf() * TAU
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * 0.25, 0.55 + rng.randf() * 0.1, sin(a) * 0.25)), Vector3(0.1, 0.1, 0.1), fruit)
	var mesh := MeshBuilder.finish(st)
	_meshes[plant_kind] = mesh
	return mesh
