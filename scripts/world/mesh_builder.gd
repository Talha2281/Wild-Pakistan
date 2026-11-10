class_name MeshBuilder
extends RefCounted
## Merges many coloured boxes into ONE ArrayMesh so an animal part is a single
## draw call. All boxes share one vertex-coloured material.

static var _material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.95
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return _material


static func start() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Transform from a position and Euler rotation in degrees (pitch, yaw, roll).
static func xf(pos: Vector3, rot_deg := Vector3.ZERO) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return Transform3D(b, pos)


## Adds an axis-aligned box (in its own space) transformed by `t`.
static func box(st: SurfaceTool, t: Transform3D, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.RIGHT, Vector3.UP, Vector3.BACK],
		[Vector3.LEFT, Vector3.UP, Vector3.BACK],
		[Vector3.UP, Vector3.RIGHT, Vector3.BACK],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP],
		[Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var a: Vector3 = f[1]
		var b: Vector3 = f[2]
		var c := n * h
		var ta := a * h
		var tb := b * h
		var p0 := c - ta - tb
		var p1 := c + ta - tb
		var p2 := c + ta + tb
		var p3 := c - ta + tb
		# Godot's front faces are clockwise when seen from outside.
		if (p1 - p0).cross(p2 - p1).dot(n) > 0.0:
			var tmp := p1
			p1 = p3
			p3 = tmp
		var nw := (t.basis * n).normalized()
		for tri in [[p0, p1, p2], [p0, p2, p3]]:
			for p in tri:
				st.set_normal(nw)
				st.set_color(color)
				st.add_vertex(t * p)


## A curved chain of boxes (horns, tails). Each segment tilts by `pitch_step` and
## twists by `yaw_step` relative to the previous one; thickness tapers to 40%.
static func chain(st: SurfaceTool, base: Transform3D, segs: int, seg_len: float, thick: float, pitch_step: float, yaw_step: float, color: Color) -> void:
	var cur := base
	for i in segs:
		var k := float(i) / float(maxi(segs - 1, 1))
		var th := thick * (1.0 - 0.6 * k)
		box(st, cur * Transform3D(Basis.IDENTITY, Vector3(0.0, seg_len * 0.5, 0.0)), Vector3(th, seg_len * 1.04, th), color)
		cur = cur * Transform3D(
			Basis.from_euler(Vector3(deg_to_rad(pitch_step), deg_to_rad(yaw_step), 0.0)),
			Vector3(0.0, seg_len, 0.0))


static func finish(st: SurfaceTool) -> ArrayMesh:
	return st.commit()


static func instance(mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material()
	return mi
