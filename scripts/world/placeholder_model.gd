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


## Procedural gait. speed_ratio: 0 standing .. 1 full run. Walk uses a diagonal
## gait; above ~0.55 the animal bounds (front pair, then back pair) with a bobbing,
## pitching body, lifted feet and a swinging head. air = legs tucked while jumping.
static func animate(root: Node3D, speed_ratio: float, delta: float, air := false) -> void:
	var phase: float = root.get_meta("phase", 0.0)
	var moving := speed_ratio > 0.03
	var human := root.get_node_or_null("LegL") != null
	var run := clampf((speed_ratio - 0.45) / 0.4, 0.0, 1.0)
	if moving:
		phase += delta * (5.0 + speed_ratio * 12.0)
		root.set_meta("phase", phase)
	var amp := (0.35 + clampf(speed_ratio, 0.0, 1.0) * 0.75) if moving else 0.0
	if human:
		amp *= 0.9
	var k := clampf(delta * 14.0, 0.0, 1.0)
	for child in root.get_children():
		var n := String(child.name)
		if not n.begins_with("Leg"):
			continue
		var leg := child as Node3D
		if not leg.has_meta("base_y"):
			leg.set_meta("base_y", leg.position.y)
		var front := n.begins_with("LegF")
		var left := n in ["LegFL", "LegBL", "LegL"]
		# walk: diagonal pairs. run: front legs together, back legs together (bound).
		var walk_off := 0.0 if n in ["LegFL", "LegBR", "LegL"] else PI
		var bound_off := 0.0 if front else 0.9
		var off := lerpf(walk_off, bound_off + (0.25 if left else 0.0), run)
		var sw := sin(phase + off)
		var target := sw * amp
		var lift := maxf(0.0, cos(phase + off)) * 0.12 * (0.4 + speed_ratio) if moving else 0.0
		if air:
			target = -0.85 if front else 0.75
			lift = 0.0
		leg.rotation.x = lerpf(leg.rotation.x, target, k)
		leg.position.y = lerpf(leg.position.y, float(leg.get_meta("base_y")) + lift, k)
	# body language
	var body := root.get_node_or_null("Body") as Node3D
	var head := root.get_node_or_null("Head") as Node3D
	var bob := 0.0
	var pitch := 0.0
	if moving and not air:
		bob = absf(sin(phase * (1.0 if run > 0.5 else 2.0))) * (0.025 + 0.05 * run) * (0.5 + speed_ratio)
		pitch = sin(phase + 0.6) * (0.02 + 0.07 * run)
	elif air:
		pitch = -0.12
	if body != null:
		if not body.has_meta("base_y"):
			body.set_meta("base_y", body.position.y)
		body.position.y = lerpf(body.position.y, float(body.get_meta("base_y")) + bob, k)
		body.rotation.x = lerpf(body.rotation.x, pitch, k)
	if head != null:
		if not head.has_meta("base_y"):
			head.set_meta("base_y", head.position.y)
		head.position.y = lerpf(head.position.y, float(head.get_meta("base_y")) + bob * 1.2, k)
	if human:
		root.rotation.x = lerpf(root.rotation.x, 0.12 * run, k)
