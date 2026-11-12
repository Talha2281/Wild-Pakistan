class_name BiomeTerrain
extends StaticBody3D
## Procedural low-poly terrain with trimesh collision, driven by a biome config.
##
## Order: configure() -> add_flat_zone() for every spawn/oasis/camp -> build().
## A small shader tints the vertex colours per season and lays snow on flat faces.

const SHADER_CODE := """
shader_type spatial;
uniform float snow : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint = vec3(1.0, 1.0, 1.0);
varying float up_amount;
void vertex() {
	up_amount = NORMAL.y;
}
void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2)) * tint;
	float s = snow * smoothstep(0.55, 0.85, up_amount);
	ALBEDO = mix(c, pow(vec3(0.93, 0.95, 1.0), vec3(2.2)), s);
	ROUGHNESS = 1.0;
}
"""

var size := 200.0
var cells := 80
var amplitude := 5.5
var edge_mode := "fade"
var cfg: Dictionary = {}
var material: ShaderMaterial
var min_height := 0.0
var max_height := 0.0

var _noise := FastNoiseLite.new()
var _n_mid := 0.0
var _n_half := 1.0
var _zones: Array[Dictionary] = []


func configure(c: Dictionary) -> void:
	cfg = c
	size = c["size"]
	cells = c["cells"]
	amplitude = c["amp"]
	edge_mode = c["edge"]
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = c["freq"]
	_noise.fractal_octaves = c["octaves"]
	_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED if c["fractal"] == "ridged" else FastNoiseLite.FRACTAL_FBM
	_noise.seed = c["seed"]
	collision_layer = GameConst.LAYER_TERRAIN
	collision_mask = 0
	# Calibrate so the raw noise maps onto -amp..+amp whatever the fractal type.
	var lo := 1.0e9
	var hi := -1.0e9
	var step := size / 40.0
	for iz in 41:
		for ix in 41:
			var n := _noise.get_noise_2d(-size * 0.5 + ix * step, -size * 0.5 + iz * step)
			lo = minf(lo, n)
			hi = maxf(hi, n)
	_n_mid = (lo + hi) * 0.5
	_n_half = maxf((hi - lo) * 0.5, 0.001)


func add_flat_zone(center: Vector2, radius: float) -> void:
	_zones.append({"c": center, "r": radius, "h": raw_height(center.x, center.y) - 0.15})


## Height before flat zones are applied (used to pick valleys and peaks).
func raw_height(x: float, z: float) -> float:
	var n := _noise.get_noise_2d(x, z)
	var h := (n - _n_mid) / _n_half * amplitude
	h += _noise.get_noise_2d(x * 3.1 + 500.0, z * 3.1) * (0.5 if amplitude < 10.0 else 0.35)
	var edge := maxf(absf(x), absf(z)) / (size * 0.5)
	if edge_mode == "wall":
		h += amplitude * 1.6 * pow(smoothstep(0.72, 1.0, edge), 1.4)
	else:
		h *= 1.0 - smoothstep(0.78, 1.0, edge)
	return h


func height_at(x: float, z: float) -> float:
	var h := raw_height(x, z)
	for zone in _zones:
		var d := Vector2(x, z).distance_to(zone["c"])
		var t := 1.0 - smoothstep(zone["r"], zone["r"] * 1.8, d)
		h = lerpf(h, zone["h"], t)
	return h


## Steepness as rise over run (1.0 = 45 degrees).
func slope_at(x: float, z: float) -> float:
	var e := 1.5
	var dx := (height_at(x + e, z) - height_at(x - e, z)) / (2.0 * e)
	var dz := (height_at(x, z + e) - height_at(x, z - e)) / (2.0 * e)
	return sqrt(dx * dx + dz * dz)


func ground(p: Vector2, lift := 0.0) -> Vector3:
	return Vector3(p.x, height_at(p.x, p.y) + lift, p.y)


func random_point(rng: RandomNumberGenerator, margin := 8.0, max_slope := 0.8) -> Vector2:
	var m := size * 0.5 - margin
	var p := Vector2.ZERO
	for i in 40:
		p = Vector2(rng.randf_range(-m, m), rng.randf_range(-m, m))
		if slope_at(p.x, p.y) <= max_slope:
			return p
	return p


## The lowest gently-sloped points, spaced apart (water holes sit in valleys).
func low_points(rng: RandomNumberGenerator, count: int, min_sep: float, margin: float) -> Array[Vector2]:
	return _extreme_points(rng, count, min_sep, margin, true)


## The highest reachable points (summits and lookouts).
func high_points(rng: RandomNumberGenerator, count: int, min_sep: float, margin: float) -> Array[Vector2]:
	return _extreme_points(rng, count, min_sep, margin, false)


func _extreme_points(rng: RandomNumberGenerator, count: int, min_sep: float, margin: float, lowest: bool) -> Array[Vector2]:
	var samples: Array[Dictionary] = []
	var m := size * 0.5 - margin
	for i in 400:
		var p := Vector2(rng.randf_range(-m, m), rng.randf_range(-m, m))
		var slope := slope_at(p.x, p.y)
		if slope < (0.7 if lowest else 1.3):
			samples.append({"p": p, "h": raw_height(p.x, p.y)})
	if lowest:
		samples.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["h"] < b["h"])
	else:
		samples.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["h"] > b["h"])
	var out: Array[Vector2] = []
	for s in samples:
		var p: Vector2 = s["p"]
		var ok := p.length() > 14.0
		for q in out:
			if p.distance_to(q) < min_sep:
				ok = false
		if ok:
			out.append(p)
		if out.size() >= count:
			break
	while out.size() < count:
		out.append(random_point(rng, margin))
	return out


func set_season(tint: Color, snow: float) -> void:
	if material == null:
		return
	material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	material.set_shader_parameter("snow", snow)


func build() -> void:
	var step := size / float(cells)
	var half := size * 0.5
	var stride := cells + 1
	var heights := PackedFloat32Array()
	heights.resize(stride * stride)
	min_height = 1.0e9
	max_height = -1.0e9
	for iz in stride:
		for ix in stride:
			var h := height_at(-half + ix * step, -half + iz * step)
			heights[iz * stride + ix] = h
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)

	var low: Color = cfg["low"]
	var high: Color = cfg["high"]
	var rock: Color = cfg["rock"]
	var rock_slope: float = cfg["rock_slope"]
	var snow_h: float = cfg["snow_height"]
	var snow_col := Color(0.92, 0.94, 0.97)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in cells:
		for ix in cells:
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var p00 := Vector3(x0, heights[iz * stride + ix], z0)
			var p10 := Vector3(x0 + step, heights[iz * stride + ix + 1], z0)
			var p01 := Vector3(x0, heights[(iz + 1) * stride + ix], z0 + step)
			var p11 := Vector3(x0 + step, heights[(iz + 1) * stride + ix + 1], z0 + step)
			_add_tri(st, p00, p10, p01, low, high, rock, rock_slope, snow_h, snow_col)
			_add_tri(st, p10, p11, p01, low, high, rock, rock_slope, snow_h, snow_col)
	st.generate_normals()
	var mesh := st.commit()

	var shader := Shader.new()
	shader.code = SHADER_CODE
	material = ShaderMaterial.new()
	material.shader = shader
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	add_child(mi)

	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)

	if edge_mode == "fade":
		_add_surround(half)


## Flat sand beyond the playable edge so the map never shows a void.
func _add_surround(half: float) -> void:
	var color: Color = cfg["low"]
	var mat := PlaceholderModel.material(color.lerp(cfg["high"], 0.3), 1.0)
	var big := 1000.0
	var specs := [
		[Vector3(0.0, 0.0, -(half + big * 0.5)), Vector2(2.0 * (half + big), big)],
		[Vector3(0.0, 0.0, half + big * 0.5), Vector2(2.0 * (half + big), big)],
		[Vector3(-(half + big * 0.5), 0.0, 0.0), Vector2(big, 2.0 * half)],
		[Vector3(half + big * 0.5, 0.0, 0.0), Vector2(big, 2.0 * half)],
	]
	for s in specs:
		var plane := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = s[1]
		plane.mesh = pm
		plane.material_override = mat
		plane.position = s[0]
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plane)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, low: Color, high: Color, rock: Color, rock_slope: float, snow_h: float, snow_col: Color) -> void:
	var avg := (a.y + b.y + c.y) / 3.0
	var t := clampf(inverse_lerp(-amplitude, amplitude * 1.6, avg), 0.0, 1.0)
	var col := low.lerp(high, t)
	var normal := (b - a).cross(c - a)
	# Winding is clockwise from above, so the cross product points down.
	var steep := 1.0 - clampf(-normal.normalized().y, 0.0, 1.0)
	col = col.lerp(rock, smoothstep(rock_slope * 0.5, rock_slope, steep))
	if avg > snow_h:
		var flat := 1.0 - smoothstep(0.2, 0.5, steep)
		col = col.lerp(snow_col, clampf((avg - snow_h) / 6.0, 0.0, 1.0) * flat)
	var jitter := _noise.get_noise_2d(a.x * 7.0, a.z * 7.0) * 0.06
	col = Color(col.r + jitter, col.g + jitter, col.b + jitter)
	for v in [a, b, c]:
		st.set_color(col)
		st.add_vertex(v)
