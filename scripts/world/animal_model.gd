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
		"color": Color(0.62, 0.58, 0.52), "len": 1.5, "h": 1.0, "w": 0.3, "horns": "markhor",
		"horn_color": Color(0.82, 0.76, 0.62), "ears": "short", "tail": "short",
		"beard": true, "ruff": true, "neck": 0.9, "thick": 1.15, "belly_light": 0.35,
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
		"color": Color(0.62, 0.5, 0.35), "len": 0.6, "h": 0.34, "w": 0.4, "bl": 0.7, "leg": 0.3,
		"ears": "round", "tail": "stub", "head": 1.1, "snout": 0.3, "neck": 0.4, "belly_light": 0.3,
	},
	"hare": {
		"color": Color(0.66, 0.55, 0.42), "len": 0.55, "h": 0.38, "leg": 0.5, "ears": "long",
		"tail": "stub", "tail_tip": Color(0.95, 0.93, 0.88), "snout": 0.4, "neck": 0.5,
		"belly_light": 0.5,
	},
	"lizard": {
		"color": Color(0.52, 0.5, 0.3), "len": 0.6, "h": 0.2, "w": 0.3, "leg": 0.35, "tail": "lizard",
		"ears": "none", "neck": 0.3, "snout": 0.6, "thick": 1.4, "belly_light": 0.25,
	},
	"desert_fox": {
		"color": Color(0.88, 0.72, 0.5), "len": 0.95, "h": 0.5, "ears": "pointed", "tail": "bushy",
		"tail_tip": Color(0.97, 0.95, 0.9), "snout": 0.9, "neck": 0.8, "belly_light": 0.5,
		"leg_color": Color(0.5, 0.38, 0.26),
	},
	"red_fox": {
		"color": Color(0.78, 0.38, 0.14), "len": 1.0, "h": 0.52, "ears": "pointed", "tail": "bushy",
		"tail_tip": Color(0.97, 0.95, 0.9), "snout": 0.9, "neck": 0.8, "belly_light": 0.5,
		"leg_color": Color(0.18, 0.13, 0.1),
	},
	"black_bear": {
		"color": Color(0.1, 0.09, 0.09), "len": 1.7, "h": 1.1, "w": 0.36, "bl": 0.66, "bh": 0.45,
		"leg": 0.42, "ears": "round", "tail": "stub", "hump": 0.1, "thick": 1.7, "neck": 0.5,
		"neck_w": 0.8, "head": 1.2, "muzzle": Color(0.55, 0.42, 0.3), "belly_light": 0.05,
	},
	"brown_bear": {
		"color": Color(0.5, 0.36, 0.24), "len": 2.0, "h": 1.3, "w": 0.38, "bl": 0.66, "bh": 0.46,
		"leg": 0.42, "ears": "round", "tail": "stub", "hump": 0.16, "thick": 1.8, "neck": 0.5,
		"neck_w": 0.8, "head": 1.3, "muzzle": Color(0.62, 0.5, 0.36), "belly_light": 0.1,
	},
	"snow_leopard": {
		"color": Color(0.78, 0.78, 0.76), "len": 1.55, "h": 0.7, "w": 0.26, "bl": 0.66, "bh": 0.4,
		"leg": 0.42, "ears": "round", "tail": "long_thick", "spots": Color(0.17, 0.17, 0.2),
		"spot_n": 12, "neck": 0.7, "head": 1.0, "snout": 0.5, "thick": 1.3, "belly_light": 0.3,
	},
}

static var _cache: Dictionary = {}


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
		pivot.add_child(MeshBuilder.instance(meshes["leg"]))
		root.add_child(pivot)
	return root


## Collision capsule (radius, height) matching a species.
static func capsule_size(id: String) -> Vector2:
	var spec: Dictionary = SPECS[id]
	var r := clampf(float(spec["len"]) * 0.14, 0.1, 0.5)
	var h := maxf(float(spec["h"]), r * 2.0 + 0.02)
	return Vector2(r, h)


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
	var bw: float = L * float(spec.get("w", 0.26))
	var bl: float = L * float(spec.get("bl", 0.62))
	var bh: float = H * float(spec.get("bh", 0.36))
	var leg_h: float = H * float(spec.get("leg", 0.5))
	var belly: Color = base.lightened(float(spec.get("belly_light", 0.35)))
	var dark := Color(0.08, 0.06, 0.05)
	var st := MeshBuilder.start()

	# ---- torso
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, leg_h + bh * 0.5, 0.0)), Vector3(bw, bh, bl), base)
	MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, leg_h + bh * 0.2, 0.0)), Vector3(bw * 1.03, bh * 0.4 + 0.02, bl * 0.94), belly)
	var hump: float = spec.get("hump", 0.0)
	if hump > 0.0:
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, leg_h + bh + H * hump * 0.5 - 0.02, -bl * 0.18)), Vector3(bw * 0.9, H * hump, bl * 0.32), base)

	# ---- neck (leans forward 40 degrees); head pivot sits at its tip
	var neck_len := H * 0.45 * float(spec.get("neck", 1.0))
	var neck_w := bw * float(spec.get("neck_w", 0.55))
	var theta := deg_to_rad(40.0)
	var neck_base := Vector3(0.0, leg_h + bh * 0.8, -bl * 0.5 + 0.02)
	var neck_center := neck_base + Vector3(0.0, cos(theta) * neck_len * 0.5, -sin(theta) * neck_len * 0.5)
	var head_pos := neck_base + Vector3(0.0, cos(theta) * neck_len, -sin(theta) * neck_len)
	MeshBuilder.box(st, Transform3D(Basis(Vector3.RIGHT, -theta), neck_center), Vector3(neck_w, neck_len, neck_w), base)
	if spec.get("ruff", false):
		MeshBuilder.box(st, Transform3D(Basis(Vector3.RIGHT, -theta), neck_center + Vector3(0.0, -0.03, 0.02)), Vector3(neck_w * 1.5, neck_len * 0.8, neck_w * 1.5), belly)

	# ---- spots
	if spec.has("spots"):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var spot_color: Color = spec["spots"]
		var n := int(spec.get("spot_n", 10))
		for i in n:
			var s := rng.randf_range(0.3, 0.8) * bw * 0.35
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(rng.randf_range(-bw * 0.35, bw * 0.35), leg_h + bh + 0.006, rng.randf_range(-bl * 0.45, bl * 0.45))), Vector3(s, 0.014, s), spot_color)
			var side := 1.0 if i % 2 == 0 else -1.0
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(side * (bw * 0.5 + 0.006), leg_h + rng.randf_range(bh * 0.2, bh * 0.85), rng.randf_range(-bl * 0.45, bl * 0.45))), Vector3(0.014, s, s), spot_color)

	# ---- tail
	var tail_tip: Color = spec.get("tail_tip", base.darkened(0.3))
	var tail_y := leg_h + bh * 0.75
	var tail_style: String = spec.get("tail", "short")
	var rear := Vector3(0.0, tail_y, bl * 0.5 - 0.02)
	match tail_style:
		"short":
			MeshBuilder.box(st, MeshBuilder.xf(rear + Vector3(0.0, 0.0, L * 0.05)), Vector3(bw * 0.22, bw * 0.28, L * 0.12), tail_tip)
		"stub":
			MeshBuilder.box(st, MeshBuilder.xf(rear + Vector3(0.0, 0.0, L * 0.03)), Vector3(bw * 0.3, bw * 0.3, L * 0.07), tail_tip)
		"long_thick":
			MeshBuilder.chain(st, MeshBuilder.xf(rear, Vector3(80.0, 0.0, 0.0)), 4, L * 0.2, bw * 0.4, 11.0, 0.0, base)
		"bushy":
			MeshBuilder.chain(st, MeshBuilder.xf(rear, Vector3(100.0, 0.0, 0.0)), 2, L * 0.17, bw * 0.55, 6.0, 0.0, base.lightened(0.05))
			MeshBuilder.box(st, MeshBuilder.xf(rear + Vector3(0.0, -0.06, L * 0.36)), Vector3(bw * 0.4, bw * 0.4, L * 0.1), tail_tip)
		"lizard":
			MeshBuilder.chain(st, MeshBuilder.xf(Vector3(0.0, leg_h + bh * 0.5, bl * 0.5 - 0.02), Vector3(90.0, 0.0, 0.0)), 4, L * 0.2, bw * 0.4, 4.0, 0.0, base.darkened(0.1))

	var body_mesh := MeshBuilder.finish(st)

	# ---- head (pivot space: origin at neck tip, nose toward -Z)
	var hs := float(spec.get("head", 1.0))
	var hw := bw * 0.55 * hs
	var hh := H * 0.2 * hs
	var hl := L * 0.2 * hs
	var sl := hl * 0.8 * float(spec.get("snout", 0.5)) * 1.6
	var muzzle: Color = spec.get("muzzle", base.darkened(0.08))
	var hst := MeshBuilder.start()
	MeshBuilder.box(hst, MeshBuilder.xf(Vector3(0.0, 0.0, -hl * 0.35)), Vector3(hw, hh, hl), base)
	MeshBuilder.box(hst, MeshBuilder.xf(Vector3(0.0, -hh * 0.12, -hl * 0.85 - sl * 0.5 + hl * 0.05)), Vector3(hw * 0.7, hh * 0.6, sl), muzzle)
	MeshBuilder.box(hst, MeshBuilder.xf(Vector3(0.0, -hh * 0.05, -hl * 0.85 - sl + hl * 0.07)), Vector3(hw * 0.45, hh * 0.35, 0.04), dark)
	for side in [-1.0, 1.0]:
		MeshBuilder.box(hst, MeshBuilder.xf(Vector3(side * (hw * 0.5 + 0.004), hh * 0.15, -hl * 0.6)), Vector3(0.02, hh * 0.22, hh * 0.22), dark)
	_add_ears(hst, spec.get("ears", "none"), hw, hh, hl, base)
	_add_horns(hst, spec.get("horns", "none"), hw, hh, H, spec.get("horn_color", Color(0.2, 0.17, 0.14)))
	if spec.get("beard", false):
		MeshBuilder.box(hst, MeshBuilder.xf(Vector3(0.0, -hh * 0.5 - H * 0.1, -hl * 0.75)), Vector3(hw * 0.28, H * 0.22, hw * 0.28), belly)
	var head_mesh := MeshBuilder.finish(hst)

	# ---- one leg (pivot at the hip, hangs down)
	var t := maxf(H * 0.09 * float(spec.get("thick", 1.0)), 0.035)
	var leg_color: Color = spec.get("leg_color", base.darkened(0.25))
	var lst := MeshBuilder.start()
	MeshBuilder.box(lst, MeshBuilder.xf(Vector3(0.0, -leg_h * 0.27, 0.0)), Vector3(t, leg_h * 0.56, t), leg_color)
	MeshBuilder.box(lst, MeshBuilder.xf(Vector3(0.0, -leg_h * 0.77, 0.0)), Vector3(t * 0.75, leg_h * 0.46, t * 0.75), leg_color)
	MeshBuilder.box(lst, MeshBuilder.xf(Vector3(0.0, -leg_h + 0.02, -t * 0.15)), Vector3(t * 0.9, 0.05, t * 1.35), dark)
	var leg_mesh := MeshBuilder.finish(lst)

	var lx := bw * 0.38
	var lz := bl * 0.38
	return {
		"body": body_mesh, "head": head_mesh, "leg": leg_mesh, "head_pos": head_pos,
		"legs": {
			"LegFL": Vector3(-lx, leg_h, -lz), "LegFR": Vector3(lx, leg_h, -lz),
			"LegBL": Vector3(-lx, leg_h, lz), "LegBR": Vector3(lx, leg_h, lz),
		},
	}


static func _add_ears(st: SurfaceTool, style: String, hw: float, hh: float, hl: float, base: Color) -> void:
	var inner := base.lightened(0.15)
	for side in [-1.0, 1.0]:
		match style:
			"long":
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(side * hw * 0.5, hh * 0.5 + hh * 0.55, hl * 0.02), Vector3(-12.0, 0.0, -side * 18.0)), Vector3(hw * 0.25, hh * 1.1, hw * 0.14), inner)
			"short":
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(side * hw * 0.5, hh * 0.5 + hh * 0.2, hl * 0.02), Vector3(0.0, 0.0, -side * 30.0)), Vector3(hw * 0.3, hh * 0.5, hw * 0.16), inner)
			"round":
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(side * hw * 0.5, hh * 0.5 + hw * 0.1, hl * 0.02)), Vector3(hw * 0.35, hw * 0.35, hw * 0.16), base)
			"pointed":
				MeshBuilder.box(st, MeshBuilder.xf(Vector3(side * hw * 0.34, hh * 0.5 + hh * 0.5, hl * 0.02), Vector3(0.0, 0.0, -side * 8.0)), Vector3(hw * 0.3, hh * 1.0, hw * 0.12), inner)


static func _add_horns(st: SurfaceTool, style: String, hw: float, hh: float, H: float, color: Color) -> void:
	for side in [-1.0, 1.0]:
		var pos := Vector3(side * hw * 0.28, hh * 0.5, hl_offset())
		match style:
			"lyre":
				MeshBuilder.chain(st, MeshBuilder.xf(pos, Vector3(6.0, 0.0, -side * 16.0)), 4, H * 0.1, H * 0.05, 8.0, 0.0, color)
			"markhor":
				MeshBuilder.chain(st, MeshBuilder.xf(pos, Vector3(10.0, 0.0, -side * 12.0)), 7, H * 0.1, H * 0.07, 14.0, side * 40.0, color)
			"ibex":
				MeshBuilder.chain(st, MeshBuilder.xf(pos, Vector3(14.0, 0.0, -side * 8.0)), 6, H * 0.1, H * 0.05, 14.0, 0.0, color)
			"ram":
				MeshBuilder.chain(st, MeshBuilder.xf(pos, Vector3(-8.0, 0.0, -side * 14.0)), 5, H * 0.07, H * 0.07, 22.0, side * 12.0, color)


static func hl_offset() -> float:
	return 0.0


# ---------------------------------------------------------------- humans

## Poacher (Shikari). armed = true carries a rifle, otherwise a net pole.
static func build_human(shirt: Color, turban: Color, armed: bool) -> Node3D:
	var key := "human|%s|%s|%s" % [shirt.to_html(), turban.to_html(), str(armed)]
	if not _cache.has(key):
		var skin := Color(0.7, 0.5, 0.38)
		var cloth := Color(0.85, 0.8, 0.7)
		var wood := Color(0.35, 0.22, 0.12)
		var st := MeshBuilder.start()
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 1.15, 0.0)), Vector3(0.5, 0.7, 0.3), shirt)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 0.8, 0.0)), Vector3(0.5, 0.2, 0.32), cloth)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 1.66, 0.0)), Vector3(0.22, 0.24, 0.22), skin)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 1.62, -0.11)), Vector3(0.18, 0.1, 0.04), Color(0.12, 0.1, 0.09))
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.0, 1.84, 0.0)), Vector3(0.3, 0.16, 0.3), turban)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(-0.32, 1.12, 0.0)), Vector3(0.12, 0.55, 0.12), shirt)
		MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.32, 1.1, -0.1), Vector3(-50.0, 0.0, 0.0)), Vector3(0.12, 0.55, 0.12), shirt)
		if armed:
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.3, 1.1, -0.4)), Vector3(0.06, 0.09, 1.0), Color(0.12, 0.12, 0.13))
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.3, 1.04, -0.05)), Vector3(0.07, 0.12, 0.3), wood)
		else:
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.38, 1.0, -0.15)), Vector3(0.05, 1.8, 0.05), wood)
			MeshBuilder.box(st, MeshBuilder.xf(Vector3(0.38, 1.9, -0.15)), Vector3(0.5, 0.04, 0.5), Color(0.45, 0.4, 0.28))
		var lst := MeshBuilder.start()
		MeshBuilder.box(lst, MeshBuilder.xf(Vector3(0.0, -0.4, 0.0)), Vector3(0.2, 0.78, 0.22), cloth)
		MeshBuilder.box(lst, MeshBuilder.xf(Vector3(0.0, -0.78, -0.04)), Vector3(0.22, 0.08, 0.3), Color(0.2, 0.15, 0.1))
		_cache[key] = {"body": MeshBuilder.finish(st), "leg": MeshBuilder.finish(lst)}
	var meshes: Dictionary = _cache[key]
	var root := Node3D.new()
	root.name = "Visual"
	var body := MeshBuilder.instance(meshes["body"])
	body.name = "Body"
	root.add_child(body)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "LegL" if side < 0.0 else "LegR"
		pivot.position = Vector3(side * 0.13, 0.8, 0.0)
		pivot.add_child(MeshBuilder.instance(meshes["leg"]))
		root.add_child(pivot)
	return root
