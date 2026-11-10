class_name Interactable
extends Area3D
## Base for anything the player can act on (E key / ACT button).
## Subclasses must call super() in _ready().

@export var prompt := "Interact"


func _ready() -> void:
	collision_layer = GameConst.LAYER_AREA
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactable")


func can_interact(_player: PlayerAnimal) -> bool:
	return true


func get_prompt(_player: PlayerAnimal) -> String:
	return prompt


func interact(_player: PlayerAnimal) -> void:
	pass


func add_sphere_shape(radius: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
