class_name Carcass
extends Interactable
## Meat left by a kill. Carnivores and omnivores can feed from it; it spoils after
## a while. Spawn with Carcass.spawn(parent, position, meat).

var meat := 60.0

static var _mesh: Mesh


static func spawn(parent: Node, pos: Vector3, amount: float) -> Carcass:
	var c := Carcass.new()
	c.meat = amount
	c.position = pos
	parent.add_child(c)
	return c


func _ready() -> void:
	super()
	prompt = "Feed"
	add_to_group("carcass")
	add_sphere_shape(1.4)
	if _mesh == null:
		var st := MeshBuilder.start()
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.16, 0.0)), Vector3(0.9, 0.32, 0.45), Color(0.45, 0.2, 0.15))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.22, -0.1), Vector3(0.0, 25.0, 0.0)), Vector3(0.6, 0.18, 0.35), Color(0.62, 0.3, 0.22))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.55, 0.12, 0.1), Vector3(0.0, 30.0, 10.0)), Vector3(0.4, 0.08, 0.08), Color(0.9, 0.88, 0.8))
		_mesh = MeshBuilder.finish(st)
	add_child(MeshBuilder.instance(_mesh))
	get_tree().create_timer(100.0).timeout.connect(queue_free)


func can_interact(player: PlayerAnimal) -> bool:
	return meat > 0.0 and player.diet != "herbivore" and player.diet != "human"


func interact(player: PlayerAnimal) -> void:
	var bite := minf(meat, 28.0)
	meat -= bite
	player.stats.eat(bite)
	player.look_down(1.4)
	AudioManager.play_3d("eat", global_position)
	if meat <= 0.5:
		queue_free()
