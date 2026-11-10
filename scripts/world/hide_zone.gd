class_name HideZone
extends Area3D
## Cover. While the player is inside, enemies see them from a much shorter distance.
## A "den" also shelters from weather and cold (shelter = true).
## kind: scrub (desert), thicket (juniper), boulders (mountain), den (cave)

@export var radius := 3.0
@export var kind := "scrub"
@export var shelter := false

static var _meshes: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConst.LAYER_PLAYER
	monitoring = true
	monitorable = false

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)

	var variant := randi() % 3
	var mi := MeshBuilder.instance(_mesh_for(kind, variant, radius))
	mi.rotation.y = randf() * TAU
	add_child(mi)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerAnimal:
		(body as PlayerAnimal).enter_cover(shelter)


func _on_body_exited(body: Node3D) -> void:
	if body is PlayerAnimal:
		(body as PlayerAnimal).exit_cover(shelter)


static func _mesh_for(zone_kind: String, variant: int, zone_radius: float) -> Mesh:
	var key := "%s|%d" % [zone_kind, variant]
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var st := MeshBuilder.start()
	match zone_kind:
		"den":
			var rock := Color(0.34, 0.32, 0.3)
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(-1.5, 1.2, 0.0)), Vector3(1.2, 2.4, 3.0), rock)
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(1.5, 1.2, 0.0)), Vector3(1.2, 2.4, 3.0), rock.lightened(0.05))
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 2.6, 0.0), Vector3(0.0, 0.0, 3.0)), Vector3(4.2, 1.1, 3.2), rock.darkened(0.05))
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.7, 1.4)), Vector3(1.8, 1.4, 0.3), Color(0.08, 0.07, 0.07))
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.02, 0.0)), Vector3(2.0, 0.04, 2.6), Color(0.18, 0.15, 0.12))
		"boulders":
			for i in 5:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.0, zone_radius * 0.6)
				var s := rng.randf_range(1.0, 1.9)
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * d, s * 0.4, sin(a) * d), Vector3(rng.randf_range(-10.0, 10.0), rng.randf_range(0.0, 90.0), rng.randf_range(-10.0, 10.0))), Vector3(s * 1.3, s * 0.9, s), Color(0.42, 0.4, 0.38).lightened(rng.randf_range(-0.05, 0.08)))
		"thicket":
			for i in 9:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.0, zone_radius * 0.65)
				var s := rng.randf_range(0.8, 1.4)
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * d, s * 0.5, sin(a) * d), Vector3(0.0, rng.randf_range(0.0, 90.0), 0.0)), Vector3(s, s * 1.1, s), Color(0.2, 0.36, 0.22).lightened(rng.randf_range(-0.08, 0.1)))
		_:
			for i in 7:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.0, zone_radius * 0.6)
				var s := rng.randf_range(0.7, 1.2)
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * d, s * 0.4, sin(a) * d), Vector3(rng.randf_range(-15.0, 15.0), rng.randf_range(0.0, 90.0), rng.randf_range(-15.0, 15.0))), Vector3(s, s * 0.85, s), Color(0.5, 0.5, 0.28).lightened(rng.randf_range(-0.1, 0.1)))
	var mesh := MeshBuilder.finish(st)
	_meshes[key] = mesh
	return mesh
