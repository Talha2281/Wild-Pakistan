class_name SnareTrap
extends Interactable
## Poacher snare. Stepping on it hurts and slows you; you can disarm it safely.

var armed := true

var _ring: MeshInstance3D


func _ready() -> void:
	super()
	prompt = "Disarm snare"
	monitoring = true
	collision_mask = GameConst.LAYER_PLAYER
	add_to_group("traps")

	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.9
	sh.height = 0.6
	cs.shape = sh
	add_child(cs)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.8
	torus.rings = 8
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring.material_override = PlaceholderModel.material(Color(0.45, 0.2, 0.1))
	_ring.scale = Vector3(1.0, 0.5, 1.0)
	_ring.position.y = 0.08
	add_child(_ring)

	body_entered.connect(_on_body_entered)


func can_interact(_player: PlayerAnimal) -> bool:
	return armed


func interact(_player: PlayerAnimal) -> void:
	_disarm()
	AudioManager.play_3d("click", global_position)
	Events.toast.emit("Snare disarmed.")
	Events.game_event.emit("disarm")


func _on_body_entered(body: Node3D) -> void:
	if not armed or not (body is PlayerAnimal):
		return
	var p := body as PlayerAnimal
	_disarm()
	p.hurt(15.0)
	p.apply_net(2.5)
	AudioManager.play_3d("trap_snap", global_position)
	Events.toast.emit("Caught in a snare!")


func _disarm() -> void:
	armed = false
	_ring.material_override = PlaceholderModel.material(Color(0.3, 0.3, 0.3))
