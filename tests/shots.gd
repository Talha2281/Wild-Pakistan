extends SceneTree
## Renders screenshots for visual review (needs a GPU or software GL):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tests/shots.gd
## Output goes to user://shots (printed at the end) or the folder in env SHOT_DIR.

var _gs: Node
var _dir := "/tmp/shots"


func _initialize() -> void:
	_run()


func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_dir, name])
	print("saved ", name)


func _run() -> void:
	if OS.has_environment("SHOT_DIR"):
		_dir = OS.get_environment("SHOT_DIR")
	DirAccess.make_dir_recursive_absolute(_dir)
	_gs = root.get_node("GameState")

	# ---- main menu
	var menu: Node = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in 50:
		await process_frame
	await _save("menu")
	menu.queue_free()
	await process_frame

	# ---- animal gallery
	await _gallery()

	# ---- biomes in play
	for combo in [["thar", "chinkara"], ["ziarat", "markhor"], ["northern", "snow_leopard"]]:
		_gs.biome_id = combo[0]
		_gs.animal_id = combo[1]
		var level: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
		root.add_child(level)
		for i in 90:
			await process_frame
		await _save("game_%s" % combo[0])
		level.queue_free()
		_gs.terrain = null
		await process_frame
		await process_frame
	print("SHOTS DONE")
	quit(0)


func _gallery() -> void:
	var world := Node3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sun.light_energy = 1.3
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 40)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.5, 0.36)
	floor_mesh.material_override = fm
	world.add_child(floor_mesh)
	var ids: Array = AnimalModel.SPECS.keys()
	var i := 0
	for id in ids:
		var m := AnimalModel.build(id)
		var col := i % 4
		var row := i / 4
		m.position = Vector3(-4.5 + col * 3.0, 0.0, -3.0 + row * 3.4)
		m.rotation_degrees.y = -55.0
		world.add_child(m)
		i += 1
	var h := AnimalModel.build_human(Color(0.2, 0.35, 0.5), Color(0.9, 0.9, 0.85), true)
	h.position = Vector3(5.2, 0.0, 0.5)
	h.rotation_degrees.y = -35.0
	world.add_child(h)
	var cam := Camera3D.new()
	cam.position = Vector3(-1.5, 5.2, 9.5)
	cam.fov = 48.0
	world.add_child(cam)
	root.add_child(world)
	cam.look_at(Vector3(0.5, 0.5, 0.0))
	cam.current = true
	for k in 8:
		await process_frame
	await _save("gallery")
	# close-ups of selected species
	for pair in [["chinkara", 0], ["markhor", 1], ["snow_leopard", 2], ["brown_bear", 3]]:
		var idx: int = ids.find(pair[0])
		var target := Vector3(-4.5 + (idx % 4) * 3.0, 0.7, -3.0 + (idx / 4) * 3.4)
		cam.position = target + Vector3(2.6, 0.9, 3.6)
		cam.look_at(target)
		await _save("close_%s" % pair[0])
	world.queue_free()
	await process_frame
