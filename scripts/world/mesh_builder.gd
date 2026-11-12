class_name MeshBuilder
extends RefCounted
## Merges many coloured boxes into ONE ArrayMesh so an animal part is a single
## draw call. All boxes share one vertex-coloured material.

static var _material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
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


# ------------------------------------------------------------ smooth organic shapes

## Adds one triangle with smooth normals, winding fixed so the front faces outward.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var face := (b - a).cross(c - a)
	var avg := na + nb + nc
	# Godot front faces are clockwise seen from outside: flip when the cross points outward.
	if face.dot(avg) > 0.0:
		var tp := b
		b = c
		c = tp
		var tn := nb
		nb = nc
		nc = tn
		var tc := cb
		cb = cc
		cc = tc
	st.set_normal(na)
	st.set_color(ca)
	st.add_vertex(a)
	st.set_normal(nb)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.set_color(cc)
	st.add_vertex(c)


## Small deterministic fur variation so large areas of colour are not flat.
static func _fur(c: Color, p: Vector3, amount: float) -> Color:
	var n := sin(p.x * 37.0 + p.y * 17.0) * cos(p.z * 29.0 - p.y * 11.0)
	return c.lightened(maxf(n, 0.0) * amount) if n > 0.0 else c.darkened(-n * amount)


## Smooth ellipsoid. `belly` colours the underside and blends up the flanks.
## `rot` orients its local axes (radii are in local space).
static func ellipsoid(st: SurfaceTool, center: Vector3, radii: Vector3, color: Color, belly := Color(0, 0, 0, 0), rot := Basis.IDENTITY, seg := 10, rings := 6, fur := 0.04) -> void:
	var use_belly := belly.a > 0.0
	var verts: Array = []
	var norms: Array = []
	var cols: Array = []
	for r in range(rings + 1):
		var v := float(r) / rings
		var th := PI * v
		for sgi in range(seg):
			var u := float(sgi) / seg
			var ph := TAU * u
			var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			var lp := d * radii
			var n := (rot * Vector3(d.x / radii.x, d.y / radii.y, d.z / radii.z)).normalized()
			var wp := center + rot * lp
			var col := color
			if use_belly:
				col = belly.lerp(color, smoothstep(-0.75, 0.05, d.y))
			if fur > 0.0:
				col = _fur(col, wp, fur)
			verts.append(wp)
			norms.append(n)
			cols.append(col)
	for r in range(rings):
		for sgi in range(seg):
			var i0 := r * seg + sgi
			var i1 := r * seg + (sgi + 1) % seg
			var i2 := (r + 1) * seg + sgi
			var i3 := (r + 1) * seg + (sgi + 1) % seg
			if r > 0:
				_tri(st, verts[i0], verts[i1], verts[i2], norms[i0], norms[i1], norms[i2], cols[i0], cols[i1], cols[i2])
			if r < rings - 1:
				_tri(st, verts[i1], verts[i3], verts[i2], norms[i1], norms[i3], norms[i2], cols[i1], cols[i3], cols[i2])


## Tapered round limb from a to b (radius ra at a, rb at b). Colours blend a -> b.
static func tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, color_a: Color, color_b := Color(0, 0, 0, 0), sides := 6, cap_b := true) -> void:
	var axis := b - a
	if axis.length() < 0.0001:
		return
	var up := axis.normalized()
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var s1 := up.cross(ref).normalized()
	var s2 := up.cross(s1).normalized()
	var cb := color_b if color_b.a > 0.0 else color_a
	for i in range(sides):
		var a0 := TAU * float(i) / sides
		var a1 := TAU * float(i + 1) / sides
		var d0 := s1 * cos(a0) + s2 * sin(a0)
		var d1 := s1 * cos(a1) + s2 * sin(a1)
		var p00 := a + d0 * ra
		var p10 := a + d1 * ra
		var p01 := b + d0 * rb
		var p11 := b + d1 * rb
		_tri(st, p00, p10, p01, d0, d1, d0, color_a, color_a, cb)
		_tri(st, p10, p11, p01, d1, d1, d0, color_a, cb, cb)
		if cap_b:
			_tri(st, b, p01, p11, up, up, up, cb, cb, cb)


## A smooth bent limb/horn/tail through a list of points; radius tapers r0 -> r1.
static func curve_tube(st: SurfaceTool, pts: Array, r0: float, r1: float, color: Color, color_end := Color(0, 0, 0, 0), sides := 6) -> void:
	var n := pts.size() - 1
	for i in range(n):
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var ce := color_end if color_end.a > 0.0 else color
		tube(st, pts[i], pts[i + 1], lerpf(r0, r1, k0), lerpf(r0, r1, k1), color.lerp(ce, k0), color.lerp(ce, k1), sides, i == n - 1)


static func finish(st: SurfaceTool) -> ArrayMesh:
	return st.commit()


static func instance(mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material()
	return mi
