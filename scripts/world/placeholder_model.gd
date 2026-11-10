class_name PlaceholderModel
extends RefCounted
## Primitive helpers and the shared walk animation.
## Animal / human shapes live in AnimalModel; swap them for Blender glTF scenes
## later (see docs/ASSET_PIPELINE.md). Materials are cached per colour.

static var _mat_cache: Dictionary = {}


static func material(color: Color, rough := 0.95) -> StandardMaterial3D:
	var key := Vector4(color.r, color.g, color.b, rough)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_mat_cache[key] = m
	return m


static func box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material(color)
	return mi


static func blob(radius: float, color: Color, squash := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0 * squash
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = material(color)
	return mi


## Swings leg pivots (children named Leg*). speed_ratio: 0 standing .. 1 full run.
static func animate(root: Node3D, speed_ratio: float, delta: float) -> void:
	var phase: float = root.get_meta("phase", 0.0)
	var moving := speed_ratio > 0.03
	if moving:
		phase += delta * (4.0 + speed_ratio * 10.0)
		root.set_meta("phase", phase)
	var amp := clampf(speed_ratio, 0.0, 1.0) * 0.8 if moving else 0.0
	for child in root.get_children():
		if child.name.begins_with("Leg"):
			var offset := PI if child.name in ["LegFL", "LegBR", "LegL"] else 0.0
			(child as Node3D).rotation.x = sin(phase + offset) * amp
