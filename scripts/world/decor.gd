class_name Decor
extends RefCounted
## Builds biome scenery from the flora list in Biomes.DB.
##   - bulk plants/rocks/trees: MultiMesh (one draw call per kind, no collision)
##   - a few collidable rocks and trees: they block the Shikari's line of sight
##   - the poacher camp (tents, fire, crates)

const PALETTE := {
	"thar": {
		"shrub": Color(0.55, 0.52, 0.3), "tuft": Color(0.72, 0.64, 0.38), "pebble": Color(0.5, 0.42, 0.35),
		"rock": Color(0.58, 0.47, 0.38), "trunk": Color(0.38, 0.27, 0.18), "crown": Color(0.4, 0.5, 0.26),
	},
	"ziarat": {
		"shrub": Color(0.36, 0.44, 0.24), "tuft": Color(0.55, 0.55, 0.32), "pebble": Color(0.5, 0.46, 0.4),
		"rock": Color(0.5, 0.46, 0.4), "trunk": Color(0.42, 0.3, 0.2), "crown": Color(0.2, 0.36, 0.24),
	},
	"indus": {
		"shrub": Color(0.4, 0.46, 0.26), "tuft": Color(0.5, 0.56, 0.3), "pebble": Color(0.55, 0.5, 0.42),
		"rock": Color(0.55, 0.5, 0.42), "trunk": Color(0.34, 0.26, 0.2), "crown": Color(0.42, 0.55, 0.38),
		"reed": Color(0.62, 0.66, 0.34),
	},
	"deosai": {
		"shrub": Color(0.36, 0.44, 0.24), "tuft": Color(0.42, 0.55, 0.26), "pebble": Color(0.5, 0.48, 0.44),
		"rock": Color(0.5, 0.47, 0.42), "trunk": Color(0.3, 0.22, 0.16), "crown": Color(0.2, 0.34, 0.22),
		"reed": Color(0.5, 0.6, 0.3),
	},
	"northern": {
		"shrub": Color(0.45, 0.45, 0.35), "tuft": Color(0.6, 0.58, 0.4), "pebble": Color(0.5, 0.5, 0.5),
		"rock": Color(0.42, 0.4, 0.4), "trunk": Color(0.3, 0.22, 0.16), "crown": Color(0.16, 0.3, 0.22),
	},
}


static func build(level: Node3D, terrain: BiomeTerrain, rng: RandomNumberGenerator, biome_id: String, flora: Array) -> void:
	var pal: Dictionary = PALETTE[biome_id]
	for entry in flora:
		var count: int = entry["count"]
		match entry["kind"]:
			"shrub":
				var m := SphereMesh.new()
				m.radius = 0.5
				m.height = 0.7
				m.radial_segments = 6
				m.rings = 3
				_scatter(level, terrain, rng, [m], [PlaceholderModel.material(pal["shrub"])], [Vector3.ZERO], count, 0.6, 1.4, 1.0)
			"tuft":
				var m := CylinderMesh.new()
				m.top_radius = 0.0
				m.bottom_radius = 0.25
				m.height = 0.6
				m.radial_segments = 5
				m.rings = 1
				_scatter(level, terrain, rng, [m], [PlaceholderModel.material(pal["tuft"])], [Vector3(0.0, 0.3, 0.0)], count, 0.6, 1.3, 1.0)
			"pebble":
				var m := SphereMesh.new()
				m.radius = 0.3
				m.height = 0.4
				m.radial_segments = 5
				m.rings = 3
				_scatter(level, terrain, rng, [m], [PlaceholderModel.material(pal["pebble"])], [Vector3.ZERO], count, 0.5, 1.5, 1.0)
			"snowrock":
				var m := BoxMesh.new()
				m.size = Vector3(1.4, 0.9, 1.1)
				_scatter(level, terrain, rng, [m], [PlaceholderModel.material(Color(0.82, 0.84, 0.88))], [Vector3(0.0, 0.3, 0.0)], count, 0.6, 2.0, 1.2)
			"rock":
				_solid_rocks(level, terrain, rng, count, 1.0, 2.4, pal["rock"])
			"boulder":
				_solid_rocks(level, terrain, rng, count, 2.6, 5.0, pal["rock"].darkened(0.08))
			"reed":
				var m := CylinderMesh.new()
				m.top_radius = 0.0
				m.bottom_radius = 0.1
				m.height = 1.9
				m.radial_segments = 4
				m.rings = 1
				_scatter(level, terrain, rng, [m], [_vmat(pal.get("reed", pal["tuft"]))], [Vector3(0.0, 0.95, 0.0)], count, 0.7, 1.4, 1.0, bool(entry.get("river", false)))
			"flower":
				var m := SphereMesh.new()
				m.radius = 0.13
				m.height = 0.2
				m.radial_segments = 5
				m.rings = 2
				_scatter(level, terrain, rng, [m], [_vmat(Color(1, 1, 1))], [Vector3(0.0, 0.3, 0.0)], count, 0.8, 1.5, 1.0, false, [Color(0.98, 0.85, 0.2), Color(0.95, 0.95, 0.9), Color(0.7, 0.45, 0.85), Color(0.95, 0.5, 0.65)])
			"tamarisk":
				_multi_trees(level, terrain, rng, count, pal, 2.0)
				_solid_trees(level, terrain, rng, mini(count / 6, 12), pal, false)
			"khejri":
				_solid_trees(level, terrain, rng, count, pal, false)
			"juniper":
				_multi_trees(level, terrain, rng, count, pal, 0.0)
				_solid_trees(level, terrain, rng, mini(count / 6, 26), pal, true)
			"pine":
				_multi_trees(level, terrain, rng, count, pal, 1.0)
				_solid_trees(level, terrain, rng, mini(count / 4, 20), pal, true)


static var _vmats: Dictionary = {}


## Material that multiplies per-instance colours (natural variation between plants).
static func _vmat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _vmats.has(key):
		var m := PlaceholderModel.material(color).duplicate() as StandardMaterial3D
		m.vertex_color_use_as_albedo = true
		_vmats[key] = m
	return _vmats[key]


static func _river_point(terrain: BiomeTerrain, rng: RandomNumberGenerator) -> Vector2:
	var half := terrain.size * 0.5
	var z := rng.randf_range(-half * 0.85, half * 0.85)
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var hw := float(terrain.cfg["river"]["width"]) * 0.5
	return Vector2(terrain.river_x(z) + side * rng.randf_range(hw + 1.0, hw + 12.0), z)


static func _scatter(level: Node3D, terrain: BiomeTerrain, rng: RandomNumberGenerator, meshes: Array, mats: Array, offsets: Array, count: int, min_s: float, max_s: float, tall: float, near_river := false, palette: Array = []) -> void:
	var transforms: Array[Transform3D] = []
	var tints: Array[Color] = []
	for i in count:
		var p := _free_point(terrain, rng, 4.0, 1.1)
		if near_river and terrain.cfg.has("river"):
			p = _river_point(terrain, rng)
		if palette.is_empty():
			var v := rng.randf_range(0.78, 1.12)
			tints.append(Color(v, v * rng.randf_range(0.95, 1.06), v * rng.randf_range(0.9, 1.05)))
		else:
			tints.append(palette[rng.randi() % palette.size()])
		var s := rng.randf_range(min_s, max_s)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3) * tall, s))
		transforms.append(Transform3D(basis, terrain.ground(p)))
	for k in meshes.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = meshes[k]
		mm.instance_count = count
		for i in count:
			var t := transforms[i]
			t.origin += t.basis * (offsets[k] as Vector3)
			mm.set_instance_transform(i, t)
			mm.set_instance_color(i, tints[i])
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = _vmat((mats[k] as StandardMaterial3D).albedo_color) if palette.is_empty() else mats[k]
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(inst)


## Non-colliding forest: trunk + crown layers sharing the same transforms.
## style 0 = juniper (round crown), 1 = pine (stacked cones).
static func _multi_trees(level: Node3D, terrain: BiomeTerrain, rng: RandomNumberGenerator, count: int, pal: Dictionary, style: float) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.2
	trunk.height = 2.0
	trunk.radial_segments = 5
	trunk.rings = 1
	var meshes: Array = [trunk]
	var mats: Array = [PlaceholderModel.material(pal["trunk"])]
	var offs: Array = [Vector3(0.0, 1.0, 0.0)]
	if style > 1.5:
		for c in 2:
			var crown := SphereMesh.new()
			crown.radius = 1.5 - c * 0.45
			crown.height = (2.0 - c * 0.6)
			crown.radial_segments = 7
			crown.rings = 3
			meshes.append(crown)
			mats.append(PlaceholderModel.material(pal["crown"].lightened(c * 0.08)))
			offs.append(Vector3(0.5 * c, 2.2 + c * 0.7, 0.3 * c))
	elif style < 0.5:
		var crown := SphereMesh.new()
		crown.radius = 1.3
		crown.height = 2.6
		crown.radial_segments = 6
		crown.rings = 3
		meshes.append(crown)
		mats.append(PlaceholderModel.material(pal["crown"]))
		offs.append(Vector3(0.0, 2.8, 0.0))
	else:
		for layer in 2:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 1.5 - layer * 0.5
			cone.height = 2.4
			cone.radial_segments = 6
			cone.rings = 1
			meshes.append(cone)
			mats.append(PlaceholderModel.material(pal["crown"].lightened(layer * 0.05)))
			offs.append(Vector3(0.0, 2.6 + layer * 1.3, 0.0))
	_scatter(level, terrain, rng, meshes, mats, offs, count, 0.8, 1.7, 1.0)


static func _solid_rocks(level: Node3D, terrain: BiomeTerrain, rng: RandomNumberGenerator, count: int, min_s: float, max_s: float, color: Color) -> void:
	for i in count:
		var p := _free_point(terrain, rng, 10.0, 1.0)
		var s := rng.randf_range(min_s, max_s)
		var size := Vector3(s * 1.4, s * 0.9, s)
		var body := StaticBody3D.new()
		body.collision_layer = GameConst.LAYER_TERRAIN
		body.position = terrain.ground(p, s * 0.25)
		body.rotation.y = rng.randf() * TAU
		body.add_child(PlaceholderModel.box(size, color.lightened(rng.randf_range(-0.05, 0.08))))
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		level.add_child(body)


static func _solid_trees(level: Node3D, terrain: BiomeTerrain, rng: RandomNumberGenerator, count: int, pal: Dictionary, evergreen: bool) -> void:
	for i in count:
		var p := _free_point(terrain, rng, 12.0, 0.9)
		var body := StaticBody3D.new()
		body.collision_layer = GameConst.LAYER_TERRAIN
		body.position = terrain.ground(p)
		var trunk := PlaceholderModel.box(Vector3(0.4, 2.8, 0.4), pal["trunk"])
		trunk.position.y = 1.4
		body.add_child(trunk)
		var crown := PlaceholderModel.blob(1.8, pal["crown"], 0.8 if evergreen else 0.6)
		crown.position.y = 3.3
		body.add_child(crown)
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.35
		sh.height = 2.8
		cs.shape = sh
		cs.position.y = 1.4
		body.add_child(cs)
		level.add_child(body)


static func _free_point(terrain: BiomeTerrain, rng: RandomNumberGenerator, margin: float, max_slope: float) -> Vector2:
	for i in 12:
		var p := terrain.random_point(rng, margin, max_slope)
		if p.length() > 7.0:
			return p
	return terrain.random_point(rng, margin, 3.0)


# ----------------------------------------------------------------- camp

## Poacher camp: tents, fire pit with a flickering light, and a few crates.
## Returns the centre so the level can place gear and a guard around it.
static func build_camp(level: Node3D, terrain: BiomeTerrain, center: Vector2) -> void:
	var root := Node3D.new()
	root.position = terrain.ground(center)
	level.add_child(root)
	var st := MeshBuilder.start()
	var canvas := Color(0.62, 0.55, 0.38)
	var canvas2 := Color(0.45, 0.5, 0.36)
	for spec in [[Vector3(-4.0, 0.0, -2.0), 20.0, canvas], [Vector3(4.5, 0.0, 1.0), -30.0, canvas2]]:
		var pos: Vector3 = spec[1 - 1]
		var yaw: float = spec[1]
		var col: Color = spec[2]
		MeshBuilder.box(st, MeshBuilder.xf(pos + Vector3(0.0, 0.85, 0.0), Vector3(0.0, yaw, 35.0)), Vector3(2.4, 0.06, 2.8), col)
		MeshBuilder.box(st, MeshBuilder.xf(pos + Vector3(0.0, 0.85, 0.0), Vector3(0.0, yaw, -35.0)), Vector3(2.4, 0.06, 2.8), col.darkened(0.08))
		MeshBuilder.box(st, MeshBuilder.xf(pos + Vector3(0.0, 0.03, 0.0), Vector3(0.0, yaw, 0.0)), Vector3(2.0, 0.06, 2.6), Color(0.2, 0.17, 0.13))
	# fire pit
	for i in 8:
		var a := float(i) / 8.0 * TAU
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(cos(a) * 0.7, 0.12, sin(a) * 0.7), Vector3(0.0, rad_to_deg(a), 0.0)), Vector3(0.3, 0.24, 0.3), Color(0.35, 0.33, 0.32))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.14, 0.0), Vector3(0.0, 30.0, 0.0)), Vector3(0.9, 0.12, 0.14), Color(0.2, 0.12, 0.08))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.14, 0.0), Vector3(0.0, -40.0, 0.0)), Vector3(0.9, 0.12, 0.14), Color(0.22, 0.14, 0.09))
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.34, 0.0), Vector3(0.0, 15.0, 0.0)), Vector3(0.25, 0.4, 0.25), Color(1.0, 0.55, 0.15))
	root.add_child(MeshBuilder.instance(MeshBuilder.finish(st)))
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.9, 0.0)
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 1.4
	light.omni_range = 9.0
	root.add_child(light)
	var tw := root.create_tween().set_loops()
	tw.tween_property(light, "light_energy", 0.9, 0.18)
	tw.tween_property(light, "light_energy", 1.5, 0.22)
	tw.tween_property(light, "light_energy", 1.1, 0.15)
