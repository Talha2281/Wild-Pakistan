class_name GuideHint
extends Control
## Little "ishara" (hint): an arrow and distance to what you need right now
## (water, food, prey, orbs, or for rangers: poachers, trapped animals, snares),
## plus a light beam standing over the target in the world.

const RANGE_HIDE := 5.0

var _arrow := Control.new()
var _label := Label.new()
var _beam: MeshInstance3D
var _target_pos := Vector3.ZERO
var _has_target := false
var _color := Color.WHITE
var _timer := 0.0
var _text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.custom_minimum_size = Vector2(44, 44)
	_arrow.size = Vector2(44, 44)
	_arrow.pivot_offset = Vector2(22, 22)
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _draw_arrow() -> void:
	var pts := PackedVector2Array([Vector2(22, 2), Vector2(40, 38), Vector2(22, 30), Vector2(4, 38)])
	_arrow.draw_colored_polygon(pts, _color)
	_arrow.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0, 0, 0, 0.8), 2.5)


func _process(delta: float) -> void:
	var pl := GameState.player as PlayerAnimal
	if pl == null or not is_instance_valid(pl):
		visible = false
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.3
		_pick(pl)
	visible = _has_target
	if _beam != null:
		_beam.visible = _has_target
	if not _has_target:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var to := _target_pos - pl.global_position
	to.y = 0.0
	var dist := to.length()
	var fwd := -cam.global_basis.z
	fwd.y = 0.0
	if fwd.length() > 0.001 and to.length() > 0.001:
		_arrow.rotation = -fwd.signed_angle_to(to, Vector3.UP)
	var vs := get_viewport_rect().size
	_arrow.position = Vector2(vs.x * 0.5 - 22.0, 168.0)
	_label.text = "%s  %d m" % [_text, int(dist)]
	_label.size = Vector2(320, 30)
	_label.position = Vector2(vs.x * 0.5 - 160.0, 214.0)
	_label.add_theme_color_override("font_color", _color)
	_arrow.queue_redraw()
	if _beam != null:
		_beam.position = _target_pos + Vector3(0, 5.0, 0)
		_beam.visible = dist > RANGE_HIDE


func _pick(pl: PlayerAnimal) -> void:
	var group := ""
	var ranger := GameState.mode != "survive"
	var cfg: Dictionary = Animals.get_cfg(GameState.animal_id)
	if ranger:
		if GameState.mode == "ranger" and _alive_nodes("shikari").size() > 0:
			group = "shikari"
			_text = "Poacher - dart (F) then arrest (E)"
			_color = Color(1.0, 0.4, 0.35)
		if get_tree().get_nodes_in_group("trapped").size() > 0 and (group == "" or randf() < 0.0):
			group = "trapped"
			_text = "Animal to rescue (E)"
			_color = Color(1.0, 0.85, 0.3)
		elif group == "" and get_tree().get_nodes_in_group("animals").size() > 0:
			group = "animals"
			_text = "Wildlife - photograph (C)"
			_color = Color(0.6, 1.0, 0.7)
		if GameState.mode == "ranger" and get_tree().get_nodes_in_group("trapped").size() > 0:
			group = "trapped"
			_text = "Animal to rescue (E)"
			_color = Color(1.0, 0.85, 0.3)
	else:
		var st := pl.stats
		if st.thirst < 60.0:
			group = "water"
			_text = "Water (E)"
			_color = Color(0.45, 0.8, 1.0)
		elif st.hunger < 60.0:
			if String(cfg["diet"]) == "carnivore":
				group = "animals"
				_text = "Prey - hunt it"
				_color = Color(1.0, 0.55, 0.4)
			else:
				group = "food_plants"
				_text = "Food (E)"
				_color = Color(0.6, 1.0, 0.5)
		else:
			group = "orbs"
			_text = "Spirit orb"
			_color = Color(0.4, 0.95, 1.0)
	var best: Node3D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group(group):
		var n3 := n as Node3D
		if n3 == null or n3 == pl:
			continue
		var d := n3.global_position.distance_squared_to(pl.global_position)
		if d < best_d:
			best_d = d
			best = n3
	_has_target = best != null
	if best != null:
		_target_pos = best.global_position
		_ensure_beam()
		var mat := _beam.material_override as StandardMaterial3D
		mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.28)
		mat.emission = _color


func _alive_nodes(group: String) -> Array:
	return get_tree().get_nodes_in_group(group)


func _ensure_beam() -> void:
	if _beam != null and is_instance_valid(_beam):
		return
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.35
	cyl.height = 10.0
	cyl.radial_segments = 8
	_beam.mesh = cyl
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission_energy_multiplier = 1.5
	m.no_depth_test = false
	_beam.material_override = m
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(_beam)


func _exit_tree() -> void:
	if _beam != null and is_instance_valid(_beam):
		_beam.queue_free()
