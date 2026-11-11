class_name SpiritOrb
extends Node3D
## Glowing collectible. Grab it by running through it: points, a combo step, a little
## stamina and a chime that rises with the combo. Cheap: one mesh, no physics.

const PICKUP_RADIUS := 1.7
static var _mesh: Mesh
static var _mat: StandardMaterial3D

var _t := randf() * TAU
var _base_y := 0.0
var _gold := false


func setup(pos: Vector3, gold: bool) -> void:
	position = pos
	_base_y = pos.y
	_gold = gold


func _ready() -> void:
	add_to_group("orbs")
	if _mesh == null:
		var s := SphereMesh.new()
		s.radius = 0.35
		s.height = 0.7
		s.radial_segments = 10
		s.rings = 6
		_mesh = s
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.82, 0.25) if _gold else Color(0.35, 0.95, 1.0)
	m.emission_enabled = true
	m.emission = m.albedo_color
	m.emission_energy_multiplier = 1.6
	mi.material_override = m
	add_child(mi)
	if _gold:
		scale = Vector3.ONE * 1.5


func _process(delta: float) -> void:
	_t += delta * 2.4
	position.y = _base_y + 0.2 * sin(_t)
	rotation.y += delta * 2.0
	var p := GameState.player as Node3D
	if p == null or not is_instance_valid(p):
		return
	var d := global_position - p.global_position
	d.y -= 0.6
	if d.length() < PICKUP_RADIUS:
		_collect(p)


func _collect(p: Node3D) -> void:
	set_process(false)
	var pts := 100 if _gold else 25
	GameState.orbs += 1
	GameState.add_score(pts, "gold orb" if _gold else "orb")
	var pa := p as PlayerAnimal
	if pa != null:
		pa.stats.stamina = minf(100.0, pa.stats.stamina + (40.0 if _gold else 12.0))
		if _gold:
			pa.stats.health = minf(pa.stats.max_health, pa.stats.health + 15.0)
	AudioManager.play_ui("orb", -3.0, 1.0 + 0.06 * float(GameState.combo - 1))
	Events.game_event.emit("orb")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.18)
	tw.tween_property(self, "position:y", position.y + 1.2, 0.18)
	tw.chain().tween_callback(queue_free)
