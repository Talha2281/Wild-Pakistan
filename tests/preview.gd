extends SceneTree
## Renders screenshots (needs a display, e.g. xvfb): one picture per species and one
## per biome. Used by the "previews" CI job so the look of the game can be reviewed.
##   xvfb-run -a godot --rendering-driver opengl3 --path . -s tests/preview.gd

const OUT := "res://../previews/"
var _gs: Node
var _frames := 0


func _initialize() -> void:
	_run()


func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + "../previews")
	img.save_png(ProjectSettings.globalize_path("res://") + "../previews/%s.png" % name)
	print("saved ", name, " ", img.get_size())


func _wait(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_gs = root.get_node("GameState")
	await _wait(5)
	# ---- species gallery
	for id in AnimalModel.SPECS:
		var holder := Node3D.new()
		root.add_child(holder)
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.62, 0.78, 0.92)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.7, 0.72, 0.78)
		e.ambient_light_energy = 0.8
		env.environment = e
		holder.add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-45, -35, 0)
		sun.shadow_enabled = true
		holder.add_child(sun)
		var ground := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(20, 20)
		ground.mesh = pm
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.55, 0.5, 0.38)
		ground.material_override = gm
		holder.add_child(ground)
		var m := AnimalModel.build(id)
		holder.add_child(m)
		var size := AnimalModel.capsule_size(id)
		var cam := Camera3D.new()
		holder.add_child(cam)
		var d := maxf(2.6, float(AnimalModel.SPECS[id]["len"]) * 2.1)
		cam.position = Vector3(d * 0.75, size.y * 0.8 + 0.35, -d * 0.85)
		cam.look_at(Vector3(0, size.y * 0.5, 0))
		cam.current = true
		await _wait(4)
		_shot("species_" + id)
		holder.queue_free()
		await _wait(2)
	# ---- biome views
	for biome in Biomes.ORDER:
		var animal: String = "chinkara"
		for a in Animals.ORDER:
			if (Animals.DB[a]["habitats"] as Array).has(biome):
				animal = a
				break
		_gs.animal_id = animal
		_gs.biome_id = biome
		var level: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(level)
		await _wait(40)
		_shot("biome_" + biome)
		level.queue_free()
		await _wait(5)
	print("PREVIEW DONE")
	quit(0)
