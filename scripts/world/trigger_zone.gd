class_name TriggerZone
extends Area3D
## A marked spot (summit cairn, ridge lookout). Entering it once fires a game event.
## When requires_climb > 0 only animals that can climb that steeply are counted
## (so a chinkara walking past a peak doesn't trigger a markhor mission).

@export var event_name := "summit"
@export var message := "You reached the summit!"
@export var radius := 3.0
@export var requires_climb := 0.0

var triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConst.LAYER_PLAYER
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	cs.position.y = 1.0
	add_child(cs)

	var st := MeshBuilder.start()
	var stone := Color(0.55, 0.52, 0.48)
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.3, 0.0), Vector3(0.0, 20.0, 0.0)), Vector3(1.2, 0.6, 1.1), stone)
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.8, 0.0), Vector3(0.0, 50.0, 0.0)), Vector3(0.8, 0.5, 0.7), stone.darkened(0.08))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 1.5, 0.0)), Vector3(0.7, 0.4, 0.5), stone.lightened(0.06))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 2.6, 0.0)), Vector3(0.08, 2.4, 0.08), Color(0.3, 0.2, 0.12))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.5, 3.4, 0.0)), Vector3(0.9, 0.55, 0.04), Color(0.1, 0.45, 0.2))
	add_child(MeshBuilder.instance(MeshBuilder.finish(st)))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if triggered or not (body is PlayerAnimal):
		return
	var p := body as PlayerAnimal
	if requires_climb > 0.0 and float(Animals.DB[p.species_id]["climb_angle"]) < requires_climb:
		return
	triggered = true
	AudioManager.play_ui("chime", -6.0)
	Events.toast.emit(message)
	Events.game_event.emit(event_name)
