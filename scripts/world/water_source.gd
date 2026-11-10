class_name WaterSource
extends Interactable
## A water hole. Thirsty wildlife also seek it out (group "water").

@export var radius := 3.5
@export var water_color := Color(0.25, 0.55, 0.7, 0.85)

var _ready_at_ms := 0


func _ready() -> void:
	super()
	prompt = "Drink"
	add_to_group("water")
	add_sphere_shape(radius)

	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.06
	cyl.radial_segments = 20
	cyl.rings = 1
	disc.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = water_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	disc.material_override = mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)


func can_interact(_player: PlayerAnimal) -> bool:
	return Time.get_ticks_msec() >= _ready_at_ms


func interact(player: PlayerAnimal) -> void:
	_ready_at_ms = Time.get_ticks_msec() + 1200
	player.stats.drink(40.0)
	player.look_down(1.2)
	AudioManager.play_3d("drink", global_position)
	Events.game_event.emit("drink")
