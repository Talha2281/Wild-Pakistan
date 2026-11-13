class_name AnimalModel
extends RefCounted
## Procedural low-poly animals and humans. Each model is just 6 draw calls
## (body, head, four legs) because all boxes of a part are merged into one mesh,
## and meshes are cached per species + colour.
##
## Conventions: forward is -Z, origin at the feet. Children: Body, Head (pivot),
## LegFL/LegFR/LegBL/LegBR (pivots). Humans: Body, LegL, LegR.
##
## SPEC KEYS (all optional except color/len/h)
##   len, h        body length / shoulder height in metres
##   w, bl, bh, leg  width, body-length, body-height, leg-height fractions
##   horns         none | lyre | markhor | ibex | ram
##   ears          none | long | short | round | pointed
##   tail          none | short | stub | long_thick | bushy | lizard
##   spots, spot_n dark rosettes (snow leopard)
##   hump, beard, ruff, thick, neck, neck_w, head, snout, muzzle, tail_tip, leg_color, belly_light

const SPECS := {
	"chinkara": {
		"color": Color(0.74, 0.54, 0.34), "len": 1.35, "h": 0.95, "horns": "lyre",
		"horn_color": Color(0.14, 0.11, 0.09), "ears": "long", "tail": "short",
		"tail_tip": Color(0.18, 0.12, 0.09), "neck": 1.0, "belly_light": 0.45,
	},
	"markhor": {
		"color": Color(0.5, 0.37, 0.26), "len": 1.5, "h": 1.0, "w": 0.3, "horns": "markhor",
		"horn_color": Color(0.36, 0.3, 0.24), "ears": "short", "tail": "short",
		"beard": true, "ruff": true, "neck": 0.9, "thick": 1.2, "belly_light": 0.0,
		"belly_color": Color(0.17, 0.12, 0.09), "leg_color": Color(0.08, 0.06, 0.05),
		"muzzle": Color(0.78, 0.74, 0.68), "shaggy": true, "knee_patch": true, "head": 1.1,
		"tail_tip": Color(0.1, 0.08, 0.06),
	},
	"ibex": {
		"color": Color(0.52, 0.4, 0.3), "len": 1.45, "h": 1.0, "horns": "ibex",
		"horn_color": Color(0.7, 0.62, 0.48), "ears": "short", "tail": "short",
		"beard": true, "neck": 0.9, "thick": 1.1, "belly_light": 0.4,
	},
	"blue_sheep": {
		"color": Color(0.55, 0.6, 0.64), "len": 1.3, "h": 0.9, "horns": "ram",
		"horn_color": Color(0.5, 0.45, 0.38), "ears": "short", "tail": "short",
		"neck": 0.8, "thick": 1.1, "belly_light": 0.5,
	},
	"marmot": {
		"paws": true,
		"color": Color(0.62, 0.5, 0.35), "len": 0.6, "h": 0.34, "w": 0.4, "bl": 0.7, "leg": 0.3,
		"ears": "round", "tail": "stub", "head": 1.1, "snout": 0.3, "neck": 0.4, "belly_light": 0.3,
	},
	"hare": {
		"paws": true,
		"color": Color(0.66, 0.55, 0.42), "len": 0.55, "h": 0.38, "leg": 0.5, "ears": "long",
		"tail": "stub", "tail_tip": Color(0.95, 0.93, 0.88), "snout": 0.4, "neck": 0.5,
		"belly_light": 0.5,
	},
	"lizard": {
		"paws": true,
		"color": Color(0.52, 0.5, 0.3), "len": 0.6, "h": 0.2, "w": 0.3, "leg": 0.35, "tail": "lizard",
		"ears": "none", "neck": 0.3, "snout": 0.6, "thick": 1.4, "belly_light": 0.25,
	},
	"desert_fox": {
		"paws": true,
		"color": Color(0.88, 0.72, 0.5), "len": 0.95, "h": 0.5, "ears": "pointed", "tail": "bushy",
		"tail_tip": Color(0.97, 0.95, 0.9), "snout": 0.9, "neck": 0.8, "belly_light": 0.5,
		"leg_color": Color(0.5, 0.38, 0.26),
	},
	"red_fox": {
		"paws": true,
		"color": Color(0.78, 0.38, 0.14), "len": 1.0, "h": 0.52, "ears": "pointed", "tail": "bushy",
		"tail_tip": Color(0.97, 0.95, 0.9), "snout": 0.9, "neck": 0.8, "belly_light": 0.5,
		"leg_color": Color(0.18, 0.13, 0.1),
	},
	"black_bear": {
		"color": Color(0.1, 0.09, 0.09), "len": 1.7, "h": 1.1, "w": 0.36, "bl": 0.66, "bh": 0.45,
		"leg": 0.42, "ears": "round", "tail": "stub", "hump": 0.1, "thick": 1.7, "neck": 0.5,
		"neck_w": 0.8, "head": 1.2, "muzzle": Color(0.55, 0.42, 0.3), "belly_light": 0.05,
		"chest_mark": Color(0.92, 0.9, 0.85), "paws": true,
	},
	"brown_bear": {
		"paws": true,
		"color": Color(0.5, 0.36, 0.24), "len": 2.0, "h": 1.3, "w": 0.38, "bl": 0.66, "bh": 0.46,
		"leg": 0.42, "ears": "round", "tail": "stub", "hump": 0.16, "thick": 1.8, "neck": 0.5,
		"neck_w": 0.8, "head": 1.3, "muzzle": Color(0.62, 0.5, 0.36), "belly_light": 0.1,
	},
	"snow_leopard": {
		"paws": true,
		"color": Color(0.78, 0.78, 0.76), "len": 1.55, "h": 0.7, "w": 0.26, "bl": 0.66, "bh": 0.4,
		"leg": 0.42, "ears": "round", "tail": "long_thick", "spots": Color(0.17, 0.17, 0.2),
		"spot_n": 12, "neck": 0.7, "head": 1.0, "snout": 0.5, "thick": 1.3, "belly_light": 0.3,
	},
	"wild_boar": {
		"paws": true,
		"color": Color(0.27, 0.21, 0.17), "len": 1.4, "h": 0.78, "w": 0.34, "bl": 0.68, "bh": 0.46,
		"leg": 0.36, "ears": "pointed", "tail": "stub", "hump": 0.12, "thick": 1.5, "neck": 0.35,
		"neck_w": 0.9, "head": 1.25, "snout": 1.2, "muzzle": Color(0.4, 0.32, 0.26), "belly_light": 0.15,
	},
	"jackal": {
		"paws": true,
		"color": Color(0.66, 0.56, 0.38), "len": 1.0, "h": 0.55, "ears": "pointed", "tail": "bushy",
		"tail_tip": Color(0.15, 0.12, 0.1), "snout": 0.95, "neck": 0.85, "belly_light": 0.4,
		"leg_color": Color(0.5, 0.4, 0.28),
	},
	"striped_hyena": {
		"paws": true,
		"color": Color(0.6, 0.55, 0.46), "len": 1.35, "h": 0.8, "w": 0.28, "bl": 0.66, "bh": 0.42,
		"leg": 0.46, "ears": "pointed", "tail": "bushy", "hump": 0.14, "spots": Color(0.15, 0.14, 0.14),
		"spot_n": 9, "snout": 0.8, "neck": 0.8, "thick": 1.15, "ruff": true, "belly_light": 0.2,
	},
	"urial": {
		"color": Color(0.68, 0.5, 0.34), "len": 1.35, "h": 0.88, "horns": "ram",
		"horn_color": Color(0.42, 0.35, 0.28), "ears": "short", "tail": "short", "beard": true,
		"neck": 0.8, "thick": 1.1, "belly_light": 0.5,
	},
	"marco_polo": {
		"color": Color(0.8, 0.74, 0.64), "len": 1.65, "h": 1.08, "w": 0.3, "horns": "ram",
		"horn_color": Color(0.74, 0.67, 0.5), "ears": "short", "tail": "short", "ruff": true,
		"neck": 0.9, "thick": 1.2, "belly_light": 0.55,
	},
	"musk_deer": {
		"paws": true,
		"color": Color(0.45, 0.37, 0.27), "len": 0.9, "h": 0.58, "leg": 0.52, "ears": "long",
		"tail": "stub", "snout": 0.8, "neck": 0.8, "w": 0.25, "belly_light": 0.4,
	},
}

static var _cache: Dictionary = {}


## Indus river dolphin: long beak, small eye, low dorsal, broad flippers and flukes.
## Forward is -Z. One mesh, cached.
static func build_dolphin() -> Node3D:
	if not _cache.has("indus_dolphin"):
		var st := MeshBuilder.start()
		var col := Color(0.5, 0.47, 0.48)
		var belly := Color(0.84, 0.72, 0.7)
		MeshBuilder.ellipsoid(st, Vector3(0, 0, 0.1), Vector3(0.3, 0.32, 0.95), col, belly, Basis.IDENTITY, 12, 8, 0.02)
		MeshBuilder.ellipsoid(st, Vector3(0, 0.03, -0.78), Vector3(0.23, 0.25, 0.36), col, belly, Basis.IDENTITY, 10, 6, 0.02)
		MeshBuilder.tube(st, Vector3(0, -0.03, -1.0), Vector3(0, -0.05, -1.85), 0.075, 0.032, col, belly, 8)
		MeshBuilder.curve_tube(st, [Vector3(0, 0, 0.8), Vector3(0, 0.02, 1.25), Vector3(0, 0.06, 1.7)], 0.2, 0.06, col, col, 8)
		MeshBuilder.ellipsoid(st, Vector3(0, 0.07, 1.78), Vector3(0.52, 0.03, 0.17), col, Color(0, 0, 0, 0), Basis.IDENTITY, 10, 4, 0.0)
		MeshBuilder.ellipsoid(st, Vector3(0, 0.36, 0.35), Vector3(0.03, 0.15, 0.2), col, Color(0, 0, 0, 0), Basis.from_euler(Vector3(deg_to_rad(-25.0), 0.0, 0.0)), 8, 4, 0.0)
		for side: float in [-1.0, 1.0]:
			MeshBuilder.ellipsoid(st, Vector3(side * 0.36, -0.14, -0.42), Vector3(0.22, 0.035, 0.13), col, Color(0, 0, 0, 0), Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(side * -25.0))), 8, 4, 0.0)
			MeshBuilder.ellipsoid(st, Vector3(side * 0.11, 0.1, -1.0), Vector3(0.03, 0.03, 0.03), Color(0.05, 0.05, 0.05), Color(0, 0, 0, 0), Basis.IDENTITY, 5, 3, 0.0)
		_cache["indus_dolphin"] = MeshBuilder.finish(st)
	var root := Node3D.new()
	root.name = "Visual"
	var body := MeshBuilder.instance(_cache["indus_dolphin"])
	body.name = "Body"
	root.add_child(body)
	return root


## Builds a model for a species. tint (alpha > 0) replaces the base colour (skins).
static func build(id: String, tint := Color(0, 0, 0, 0)) -> Node3D:
	var spec: Dictionary = SPECS[id]
	var base: Color = spec["color"]
	if tint.a > 0.0:
		base = tint
	var key := id + "|" + base.to_html()
	if not _cache.has(key):
		_cache[key] = _make_meshes(id, spec, base)
	var meshes: Dictionary = _cache[key]

	var root := Node3D.new()
	root.name = "Visual"
	var body := MeshBuilder.instance(meshes["body"])
	body.name = "Body"
	root.add_child(body)

	var head := Node3D.new()
	head.name = "Head"
	head.position = meshes["head_pos"]
	head.add_child(MeshBuilder.instance(meshes["head"]))
	root.add_child(head)

	var leg_pos: Dictionary = meshes["legs"]
	for leg_name in leg_pos:
		var pivot := Node3D.new()
		pivot.name = leg_name
		pivot.position = leg_pos[leg_name]
		var front: bool = String(leg_name).begins_with("LegF")
		pivot.add_child(MeshBuilder.instance(meshes["leg_f"] if front else meshes["leg_b"]))
		root.add_child(pivot)
	return root


## Collision capsule (radius, height) matching a species.
static func capsule_size(id: String) -> Vector2:
	if id == "ranger":
		return Vector2(0.35, 1.75)
	var spec: Dictionary = SPECS[id]
	var r := clampf(float(spec["len"]) * 0.14, 0.1, 0.5)
	var h := maxf(float(spec["h"]), r * 2.0 + 0.02)
	return Vector2(r, h)


## Shoulder height used to place the camera.
static func body_height(id: String) -> float:
	return 1.75 if id == "ranger" else float(SPECS[id]["h"])


## Park ranger: forest-green uniform, cap, rifle-style dart gun.
static func build_ranger(uniform: Color) -> Node3D:
	return build_human(uniform, uniform.darkened(0.35), true)


## Lerps the head up/down. amount 0 = level, 1 = head to the ground.
static func pose_head(root: Node3D, amount: float, delta: float) -> void:
	var head := root.get_node_or_null("Head") as Node3D
	if head == null:
		return
	var target := -0.95 * amount
	head.rotation.x = lerpf(head.rotation.x, target, clampf(delta * 6.0, 0.0, 1.0))


static func _make_meshes(id: String, spec: Dictionary, base: Color) -> Dictionary:
	var L: float = spec["len"]
	var H: float = spec["h"]
	var thick: float = spec.get("thick", 1.0)
	var bw: float = L * float(spec.get("w", 0.26)) * (0.9 + 0.1 * thick)
	var bl: float = L * float(spec.get("bl", 0.62))
	var bh: float = H * float(spec.get("bh", 0.36))
	var leg_h: float = H * float(spec.get("leg", 0.5))
	var belly: Color = spec.get("belly_color", base.lightened(float(spec.get("belly_light", 0.35))))
	var dark := Color(0.08, 0.06, 0.05)
	var st := MeshBuilder.start()
	var cy := leg_h + bh * 0.5

	# ---- torso: chest + belly + haunch blend into one smooth form
	MeshBuilder.ellipsoid(st, Vector3(0.0, cy, 0.0), Vector3(bw * 0.5, bh * 0.5, bl * 0.4), base, belly, Basis.IDENTITY, 16, 10)
	MeshBuilder.ellipsoid(st, Vector3(0.0, cy + bh * 0.04, -bl * 0.25), Vector3(bw * 0.52, bh * 0.54, bl * 0.27), base, belly, Basis.IDENTITY, 16, 10)
	MeshBuilder.ellipsoid(st, Vector3(0.0, cy + bh * 0.02, bl * 0.27), Vector3(bw * 0.5, bh * 0.52, bl * 0.26), base, belly, Basis.IDENTITY, 16, 10)
	var hump: float = spec.get("hump", 0.0)
	if hump > 0.0:
		MeshBuilder.ellipsoid(st, Vector3(0.0, leg_h + bh * 0.92 + H * hump * 0.3, -bl * 0.2), Vector3(bw * 0.46, H * hump * 0.8, bl * 0.2), base, Color(0, 0, 0, 0), Basis.IDENTITY, 10, 5)
	var rump: Color = spec.get("rump", Color(0, 0, 0, 0))
	if rump.a > 0.0:
		MeshBuilder.ellipsoid(st, Vector3(0.0, cy + bh * 0.1, bl * 0.46), Vector3(bw * 0.38, bh * 0.38, bl * 0.08), rump, Color(0, 0, 0, 0), Basis.IDENTITY, 8, 5, 0.0)
	var chest_mark: Color = spec.get("chest_mark", Color(0, 0, 0, 0))
	if chest_mark.a > 0.0:
		MeshBuilder.ellipsoid(st, Vector3(0.0, cy - bh * 0.05, -bl * 0.46), Vector3(bw * 0.28, bh * 0.28, bl * 0.06), chest_mark, Color(0, 0, 0, 0), Basis.IDENTITY, 8, 5, 0.0)

	# ---- neck: tapered tube from the shoulders up and forward to the head pivot
	var neck_len := H * 0.5 * float(spec.get("neck", 1.0))
	var neck_w := bw * float(spec.get("neck_w", 0.55))
	var theta := deg_to_rad(float(spec.get("neck_angle", 42.0)))
	var neck_base := Vector3(0.0, leg_h + bh * 0.72, -bl * 0.34)
	var head_pos := neck_base + Vector3(0.0, cos(theta) * neck_len, -sin(theta) * neck_len)
	MeshBuilder.tube(st, neck_base, head_pos, neck_w * 0.62, neck_w * 0.38, base, base.lightened(0.04), 8, false)
	if spec.get("ruff", false):
		MeshBuilder.ellipsoid(st, neck_base.lerp(head_pos, 0.45) + Vector3(0.0, -0.04, 0.03), Vector3(neck_w * 0.85, neck_len * 0.5, neck_w * 0.85), belly, Color(0, 0, 0, 0), Basis.from_euler(Vector3(-theta, 0.0, 0.0)), 8, 5, 0.06)

	# ---- shaggy coat: mane, chest beard and belly fringe from many thin strands
	if spec.get("shaggy", false):
		var fr := RandomNumberGenerator.new()
		fr.seed = hash(id) + 7
		var dk: Color = belly
		for i in 70:
			var t := fr.randf()
			var a := fr.randf_range(-1.1, 1.1)
			var at := neck_base.lerp(head_pos, t * 0.9) + Vector3(sin(a) * neck_w * 0.55, cos(a) * neck_w * 0.5 - neck_w * 0.1, 0.0)
			MeshBuilder.tuft(st, at, Vector3(sin(a) * 0.5, -1.0, 0.45), H * fr.randf_range(0.14, 0.26), H * 0.012, dk.lerp(base, 0.25), dk.darkened(0.15))
		for i in 34:
			var zz := fr.randf_range(-bl * 0.4, bl * 0.38)
			var sd := -1.0 if fr.randf() < 0.5 else 1.0
			MeshBuilder.tuft(st, Vector3(sd * bw * 0.36, cy - bh * 0.28, zz), Vector3(sd * 0.25, -1.0, 0.2), H * fr.randf_range(0.1, 0.18), H * 0.011, base.lerp(dk, 0.4), dk)
		for i in 24:
			var zz := fr.randf_range(-bl * 0.15, bl * 0.4)
			MeshBuilder.tuft(st, Vector3(fr.randf_range(-bw * 0.2, bw * 0.2), cy + bh * 0.5, zz), Vector3(0.0, 0.5, 1.0), H * 0.12, H * 0.012, base.lightened(0.1), base.darkened(0.1))

	# ---- spots (rosettes along back and flanks)
	if spec.has("spots"):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var spot_color: Color = spec["spots"]
		var n := int(spec.get("spot_n", 12)) * 3
		for i in n:
			var ang := rng.randf_range(deg_to_rad(-25.0), deg_to_rad(205.0))
			var zz := rng.randf_range(-bl * 0.42, bl * 0.42)
			var k := 1.0 + 0.012
			var pos := Vector3(cos(ang) * bw * 0.5 * k, cy + sin(ang) * bh * 0.5 * k, zz)
			var nrm := Vector3(cos(ang) / (bw * 0.5), sin(ang) / (bh * 0.5), 0.0).normalized()
			var bx := nrm.cross(Vector3.FORWARD).normalized()
			var bz := bx.cross(nrm).normalized()
			var sz := rng.randf_range(0.035, 0.07) * L * 0.6
			var bs := Basis(bx, nrm, bz)
			MeshBuilder.ellipsoid(st, pos, Vector3(sz, sz * 0.3, sz * 0.8), spot_color, Color(0, 0, 0, 0), bs, 6, 3, 0.0)

	# ---- tail
	var tail_tip: Color = spec.get("tail_tip", base.darkened(0.3))
	var tail_y := leg_h + bh * 0.78
	var rear := Vector3(0.0, tail_y, bl * 0.5 - 0.02)
	match String(spec.get("tail", "short")):
		"short":
			MeshBuilder.tube(st, rear, rear + Vector3(0.0, 0.06, L * 0.13), bw * 0.1, bw * 0.06, base, tail_tip, 6)
		"stub":
			MeshBuilder.ellipsoid(st, rear + Vector3(0.0, 0.0, L * 0.03), Vector3(bw * 0.12, bw * 0.12, L * 0.04), tail_tip, Color(0, 0, 0, 0), Basis.IDENTITY, 6, 4)
		"long_thick":
			var pts: Array = []
			for i in 7:
				var t := float(i) / 6.0
				pts.append(rear + Vector3(0.0, -0.05 - 0.3 * L * 0.5 * sin(t * 2.4) * 0.5 + t * t * L * 0.1, t * L * 0.78))
			MeshBuilder.curve_tube(st, pts, bw * 0.24, bw * 0.17, base, tail_tip, 7)
		"bushy":
			MeshBuilder.ellipsoid(st, rear + Vector3(0.0, -0.07, L * 0.2), Vector3(bw * 0.34, bw * 0.34, L * 0.22), base.lightened(0.05), Color(0, 0, 0, 0), Basis.from_euler(Vector3(-0.35, 0.0, 0.0)), 8, 5, 0.05)
			MeshBuilder.ellipsoid(st, rear + Vector3(0.0, -0.17, L * 0.36), Vector3(bw * 0.28, bw * 0.28, L * 0.1), tail_tip, Color(0, 0, 0, 0), Basis.from_euler(Vector3(-0.5, 0.0, 0.0)), 8, 4, 0.0)
		"lizard":
			var lp: Array = []
			for i in 6:
				var t := float(i) / 5.0
				lp.append(Vector3(0.0, leg_h + bh * 0.4 - t * leg_h * 0.8, bl * 0.45 + t * L * 0.55))
			MeshBuilder.curve_tube(st, lp, bw * 0.3, bw * 0.05, base.darkened(0.05), base.darkened(0.2), 6)
	var body_mesh := MeshBuilder.finish(st)

	# ---- head (pivot space: origin at neck tip, nose toward -Z)
	var hs: float = spec.get("head", 1.0)
	var hw := bw * 0.62 * hs
	var hh := H * 0.21 * hs
	var hl := L * 0.2 * hs
	var sl := hl * 0.5 * float(spec.get("snout", 0.5)) * 1.6
	var muzzle: Color = spec.get("muzzle", base.darkened(0.06))
	var hst := MeshBuilder.start()
	MeshBuilder.ellipsoid(hst, Vector3(0.0, 0.0, -hl * 0.28), Vector3(hw * 0.5, hh * 0.52, hl * 0.52), base, belly, Basis.IDENTITY, 14, 9)
	var tip := Vector3(0.0, -hh * 0.2, -hl * 0.74 - sl)
	MeshBuilder.tube(hst, Vector3(0.0, -hh * 0.05, -hl * 0.55), tip, hh * 0.34, hh * 0.22, base.lerp(muzzle, 0.5), muzzle, 8, false)
	MeshBuilder.ellipsoid(hst, tip + Vector3(0.0, 0.0, 0.01), Vector3(hh * 0.2, hh * 0.15, hh * 0.14), dark, Color(0, 0, 0, 0), Basis.IDENTITY, 8, 4, 0.0)
	MeshBuilder.ellipsoid(hst, Vector3(0.0, -hh * 0.36, -hl * 0.45), Vector3(hw * 0.28, hh * 0.2, hl * 0.3), belly, Color(0, 0, 0, 0), Basis.IDENTITY, 8, 4)
	for side: float in [-1.0, 1.0]:
		MeshBuilder.ellipsoid(hst, Vector3(side * hw * 0.44, hh * 0.14, -hl * 0.5), Vector3(hh * 0.07, hh * 0.11, hh * 0.11), dark, Color(0, 0, 0, 0), Basis.IDENTITY, 6, 4, 0.0)
		if spec.get("face_stripe", false):
			MeshBuilder.tube(hst, Vector3(side * hw * 0.4, hh * 0.1, -hl * 0.55), tip + Vector3(side * hh * 0.18, hh * 0.1, hl * 0.05), hh * 0.035, hh * 0.03, dark, dark, 4, false)
	_add_ears(hst, spec.get("ears", "none"), hw, hh, hl, base)
	_add_horns(hst, spec.get("horns", "none"), hw, hh, hl, H, spec.get("horn_color", Color(0.2, 0.17, 0.14)))
	if spec.get("beard", false):
		MeshBuilder.tube(hst, Vector3(0.0, -hh * 0.4, -hl * 0.6), Vector3(0.0, -hh * 0.4 - H * 0.16, -hl * 0.52), hw * 0.1, hw * 0.03, belly, belly, 5, true)
	var head_mesh := MeshBuilder.finish(hst)

	# ---- legs (pivot at the hip, hang down)
	var t := maxf(H * 0.09 * thick, 0.035)
	var leg_color: Color = spec.get("leg_color", base.darkened(0.18))
	var upper_color := base.darkened(0.05)
	var paws: bool = spec.get("paws", false)
	var fst := MeshBuilder.start()
	var up := bh * 0.45
	var fpts := [Vector3(0.0, up, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, -leg_h * 0.5, 0.02), Vector3(0.0, -leg_h * 0.78, 0.0), Vector3(0.0, -leg_h + 0.03, -0.01)]
	MeshBuilder.curve_tube(fst, fpts, t * 1.25, t * 0.32, upper_color, leg_color, 7)
	_add_foot(fst, Vector3(0.0, -leg_h + 0.03, -0.01), t, paws, dark)
	if spec.get("knee_patch", false):
		MeshBuilder.ellipsoid(fst, Vector3(0.0, -leg_h * 0.5, 0.02), Vector3(t * 0.62, t * 0.55, t * 0.62), Color(0.82, 0.74, 0.6), Color(0, 0, 0, 0), Basis.IDENTITY, 8, 5, 0.0)
	var bst := MeshBuilder.start()
	var bpts := [Vector3(0.0, up, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, -leg_h * 0.42, -t * 1.4), Vector3(0.0, -leg_h * 0.74, t * 1.1), Vector3(0.0, -leg_h + 0.03, 0.0)]
	MeshBuilder.curve_tube(bst, bpts, t * 1.5, t * 0.32, upper_color, leg_color, 7)
	_add_foot(bst, Vector3(0.0, -leg_h + 0.03, 0.0), t, paws, dark)
	if spec.get("knee_patch", false):
		MeshBuilder.ellipsoid(bst, Vector3(0.0, -leg_h * 0.42, -t * 1.4), Vector3(t * 0.6, t * 0.5, t * 0.6), Color(0.82, 0.74, 0.6), Color(0, 0, 0, 0), Basis.IDENTITY, 8, 5, 0.0)

	var lx := bw * 0.36
	var lz := bl * 0.3
	return {
		"body": body_mesh, "head": head_mesh, "leg_f": MeshBuilder.finish(fst), "leg_b": MeshBuilder.finish(bst),
		"head_pos": head_pos,
		"legs": {
			"LegFL": Vector3(-lx, leg_h, -lz), "LegFR": Vector3(lx, leg_h, -lz),
			"LegBL": Vector3(-lx, leg_h, lz * 1.05), "LegBR": Vector3(lx, leg_h, lz * 1.05),
		},
	}


static func _add_foot(st: SurfaceTool, at: Vector3, t: float, paws: bool, dark: Color) -> void:
	if paws:
		MeshBuilder.ellipsoid(st, at + Vector3(0.0, -0.01, -t * 0.25), Vector3(t * 0.55, t * 0.32, t * 0.8), dark.lightened(0.12), Color(0, 0, 0, 0), Basis.IDENTITY, 8, 4, 0.0)
	else:
		MeshBuilder.tube(st, at + Vector3(0.0, 0.03, 0.0), at + Vector3(0.0, -0.025, -t * 0.12), t * 0.34, t * 0.4, dark, dark, 6, true)


static func _add_ears(st: SurfaceTool, style: String, hw: float, hh: float, hl: float, base: Color) -> void:
	var inner := base.lightened(0.18)
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * hw * 0.38, hh * 0.38, hl * 0.02)
		match style:
			"long":
				MeshBuilder.ellipsoid(st, at + Vector3(side * hw * 0.2, hh * 0.55, hl * 0.12), Vector3(hw * 0.12, hh * 0.6, hw * 0.22), inner, base, Basis.from_euler(Vector3(0.35, 0.0, -side * 0.55)), 8, 5)
			"short":
				MeshBuilder.ellipsoid(st, at + Vector3(side * hw * 0.28, hh * 0.1, hl * 0.04), Vector3(hw * 0.28, hh * 0.1, hw * 0.12), inner, base, Basis.from_euler(Vector3(0.0, 0.0, -side * 0.35)), 8, 5)
			"round":
				MeshBuilder.ellipsoid(st, at + Vector3(side * hw * 0.04, hh * 0.18, hl * 0.04), Vector3(hw * 0.17, hw * 0.17, hw * 0.08), base, inner, Basis.IDENTITY, 8, 5)
			"pointed":
				MeshBuilder.ellipsoid(st, at + Vector3(side * hw * 0.1, hh * 0.55, hl * 0.06), Vector3(hw * 0.14, hh * 0.65, hw * 0.1), base, inner, Basis.from_euler(Vector3(0.15, 0.0, -side * 0.2)), 8, 5)


static func _add_horns(st: SurfaceTool, style: String, hw: float, hh: float, hl: float, H: float, color: Color) -> void:
	if style == "none":
		return
	var tipc := color.lightened(0.15)
	for side: float in [-1.0, 1.0]:
		var base_p := Vector3(side * hw * 0.2, hh * 0.48, -hl * 0.12)
		var pts: Array = []
		var r0 := H * 0.03
		var r1 := H * 0.01
		match style:
			"lyre":
				for i in 8:
					var t := float(i) / 7.0
					pts.append(base_p + Vector3(side * (H * 0.03 * sin(t * PI) + t * H * 0.01), t * H * 0.34, t * t * H * 0.1 + t * H * 0.02))
				r0 = H * 0.026
			"markhor":
				for i in 28:
					var t := float(i) / 27.0
					var a := t * TAU * 1.5 * side
					var rr := H * 0.05 * (0.6 + t * 0.7)
					pts.append(base_p + Vector3(side * (t * H * 0.16) + cos(a) * rr * 0.9, sin(t * 1.9) * H * 0.5, t * t * H * 0.3 + sin(a) * rr))
				r0 = H * 0.05
				r1 = H * 0.012
			"ibex":
				for i in 12:
					var t := float(i) / 11.0
					pts.append(base_p + Vector3(side * (t * H * 0.07), sin(t * 1.25) * H * 0.4, t * t * H * 0.5 + t * H * 0.05))
				r0 = H * 0.04
			"ram":
				var rad := H * 0.15
				for i in 12:
					var t := float(i) / 11.0
					var a := t * PI * 1.25
					pts.append(base_p + Vector3(side * (t * H * 0.13), sin(a) * rad, (1.0 - cos(a)) * rad * 0.9))
				r0 = H * 0.045
				r1 = H * 0.014
		if pts.size() > 1:
			MeshBuilder.curve_tube(st, pts, r0, r1, color, tipc, 6)


# ---------------------------------------------------------------- humans

## Poacher (Shikari). armed = true carries a rifle, otherwise a net pole.
static func build_human(shirt: Color, turban: Color, armed: bool) -> Node3D:
	var key := "human2|%s|%s|%s" % [shirt.to_html(), turban.to_html(), str(armed)]
	if not _cache.has(key):
		var skin := Color(0.72, 0.52, 0.38)
		var cloth := Color(0.82, 0.78, 0.68)
		var wood := Color(0.36, 0.23, 0.12)
		var metal := Color(0.14, 0.14, 0.16)
		var no := Color(0, 0, 0, 0)
		var st := MeshBuilder.start()
		# kameez (long shirt) + chest + shoulders
		MeshBuilder.tube(st, Vector3(0.0, 1.42, 0.0), Vector3(0.0, 0.72, 0.0), 0.2, 0.27, shirt, shirt.darkened(0.1), 10, false)
		MeshBuilder.ellipsoid(st, Vector3(0.0, 1.38, 0.0), Vector3(0.27, 0.2, 0.17), shirt, no, Basis.IDENTITY, 10, 6)
		# head, beard, turban, shawl
		MeshBuilder.ellipsoid(st, Vector3(0.0, 1.7, 0.0), Vector3(0.105, 0.125, 0.115), skin, no, Basis.IDENTITY, 10, 6, 0.02)
		MeshBuilder.ellipsoid(st, Vector3(0.0, 1.62, -0.035), Vector3(0.09, 0.08, 0.085), Color(0.12, 0.1, 0.09), no, Basis.IDENTITY, 8, 4, 0.0)
		MeshBuilder.ellipsoid(st, Vector3(0.0, 1.83, 0.0), Vector3(0.145, 0.095, 0.15), turban, no, Basis.IDENTITY, 10, 6, 0.05)
		MeshBuilder.tube(st, Vector3(0.1, 1.82, 0.1), Vector3(0.22, 1.5, 0.12), 0.04, 0.035, turban, turban, 6, true)
		MeshBuilder.ellipsoid(st, Vector3(-0.08, 1.35, 0.0), Vector3(0.3, 0.07, 0.2), Color(0.55, 0.5, 0.4), no, Basis.from_euler(Vector3(0.0, 0.0, 0.5)), 10, 4)
		# arms
		MeshBuilder.curve_tube(st, [Vector3(-0.27, 1.42, 0.0), Vector3(-0.33, 1.16, 0.0), Vector3(-0.3, 0.98, -0.1)], 0.07, 0.05, shirt, skin, 6)
		MeshBuilder.curve_tube(st, [Vector3(0.27, 1.42, 0.0), Vector3(0.34, 1.2, -0.12), Vector3(0.28, 1.1, -0.3)], 0.07, 0.05, shirt, skin, 6)
		if armed:
			MeshBuilder.tube(st, Vector3(0.28, 1.1, 0.08), Vector3(0.28, 1.14, -1.0), 0.028, 0.02, metal, metal, 6, true)
			MeshBuilder.tube(st, Vector3(0.28, 1.08, 0.18), Vector3(0.28, 1.1, -0.2), 0.04, 0.03, wood, wood, 6, true)
		else:
			MeshBuilder.tube(st, Vector3(0.36, 0.0, -0.15), Vector3(0.36, 1.95, -0.15), 0.025, 0.025, wood, wood, 6, true)
			MeshBuilder.ellipsoid(st, Vector3(0.36, 1.95, -0.15), Vector3(0.28, 0.03, 0.28), Color(0.45, 0.4, 0.28), no, Basis.IDENTITY, 10, 3, 0.0)
		var lst := MeshBuilder.start()
		MeshBuilder.tube(lst, Vector3(0.0, 0.0, 0.0), Vector3(0.0, -0.8, 0.0), 0.1, 0.07, cloth, cloth, 7, false)
		MeshBuilder.ellipsoid(lst, Vector3(0.0, -0.84, -0.05), Vector3(0.07, 0.05, 0.13), Color(0.22, 0.16, 0.1), no, Basis.IDENTITY, 8, 4, 0.0)
		_cache[key] = {"body": MeshBuilder.finish(st), "leg": MeshBuilder.finish(lst)}
	var meshes: Dictionary = _cache[key]
	var root := Node3D.new()
	root.name = "Visual"
	var body := MeshBuilder.instance(meshes["body"])
	body.name = "Body"
	root.add_child(body)
	for side: float in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "LegL" if side < 0.0 else "LegR"
		pivot.position = Vector3(side * 0.12, 0.84, 0.0)
		pivot.add_child(MeshBuilder.instance(meshes["leg"]))
		root.add_child(pivot)
	return root
