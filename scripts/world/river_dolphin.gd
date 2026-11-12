class_name RiverDolphin
extends Node3D
## Indus river dolphin. Swims up and down the river, surfacing now and then.
## Not hunted, not a threat. Photograph it for a top rarity rating.

var species := "indus_dolphin"
var dead := false
var z := 0.0
var dir := 1.0
var speed := 2.6

var _t := 0.0
var _lane := 0.0
var _surface_in := 4.0
var _surface_t := -1.0
var _terrain: BiomeTerrain
var _visual: Node3D


func _ready() -> void:
	add_to_group("dolphins")
	_terrain = GameState.terrain
	_visual = AnimalModel.build_dolphin()
	add_child(_visual)
	_lane = randf_range(-1.0, 1.0)
	_surface_in = randf_range(3.0, 8.0)
	_place(0.0)


func _process(delta: float) -> void:
	if _terrain == null or not _terrain.cfg.has("river"):
		return
	_t += delta
	z += dir * speed * delta
	var limit := _terrain.size * 0.5 * 0.88
	if absf(z) > limit:
		dir = -signf(z)
		z = clampf(z, -limit, limit)
	_surface_in -= delta
	if _surface_in <= 0.0 and _surface_t < 0.0:
		_surface_t = 0.0
		_surface_in = randf_range(5.0, 11.0)
		AudioManager.play_3d("drink", global_position, -8.0, 0.2)
	var lift := 0.0
	if _surface_t >= 0.0:
		_surface_t += delta
		var k := clampf(_surface_t / 1.4, 0.0, 1.0)
		lift = sin(k * PI) * 0.75
		if _surface_t > 1.4:
			_surface_t = -1.0
	_place(lift)


func _place(lift: float) -> void:
	var r: Dictionary = _terrain.cfg["river"]
	var cx := _terrain.river_x(z) + _lane * float(r["width"]) * 0.22 + sin(_t * 0.7) * 1.2
	var cx2 := _terrain.river_x(z + dir * 2.0) + _lane * float(r["width"]) * 0.22
	var lvl := _terrain.river_level()
	position = Vector3(cx, lvl - 0.5 + lift, z)
	var heading := Vector3(cx2 - cx, 0.0, dir * 2.0)
	if heading.length() > 0.01:
		rotation.y = atan2(-heading.x, -heading.z)
	rotation.x = -sin(clampf(_surface_t / 1.4, 0.0, 1.0) * PI) * 0.35 if _surface_t >= 0.0 else 0.0
	_visual.rotation.z = sin(_t * 1.5) * 0.08
