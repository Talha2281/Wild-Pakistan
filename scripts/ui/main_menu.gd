extends Control
## Main menu: title, animal + habitat selection (with a rotating 3D preview, skins
## and unlock requirements), journal (missions and stats) and settings.
## Built entirely in code; screens are rebuilt whenever a choice changes.

var _content: Control
var _sel_animal := "chinkara"
var _sel_skin := 0
var _sel_biome := "thar"
var _pivot: Node3D
var _far: Polygon2D
var _near: Polygon2D
var _time := 0.0


func _ready() -> void:
	theme = UiKit.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_content = Control.new()
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var last_animal: String = SaveManager.data.get("last_animal", "chinkara")
	if Animals.DB.has(last_animal) and SaveManager.animal_unlocked(last_animal):
		_sel_animal = last_animal
	_sel_skin = SaveManager.equipped_skin(_sel_animal)
	_sel_biome = _fix_biome(String(SaveManager.data.get("last_biome", "thar")))

	AudioManager.start_ambience("amb_desert")
	AudioManager.set_environment(0.15, 0.0, 0.0)
	AudioManager.play_music("music_menu", -9.0)
	_show_main()


func _process(delta: float) -> void:
	_time += delta
	if _far != null:
		_far.position.x = sin(_time * 0.12) * 40.0
		_near.position.x = sin(_time * 0.2 + 1.0) * 70.0
	if _pivot != null and is_instance_valid(_pivot):
		_pivot.rotation.y += delta * 0.6


# ---------------------------------------------------------------- background

func _build_background() -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.07, 0.11, 0.2), Color(0.6, 0.42, 0.28), Color(0.14, 0.1, 0.08)])
	g.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 256
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var far := Polygon2D.new()
	_far = far
	far.color = Color(0.22, 0.25, 0.36)
	far.polygon = PackedVector2Array([Vector2(-400, 720), Vector2(-400, 520), Vector2(80, 420), Vector2(260, 500), Vector2(520, 330), Vector2(760, 470), Vector2(980, 380), Vector2(1250, 500), Vector2(1680, 400), Vector2(1680, 720)])
	add_child(far)
	var near := Polygon2D.new()
	_near = near
	near.color = Color(0.12, 0.1, 0.1)
	near.polygon = PackedVector2Array([Vector2(-400, 720), Vector2(-400, 640), Vector2(200, 600), Vector2(600, 650), Vector2(1000, 610), Vector2(1400, 650), Vector2(1680, 620), Vector2(1680, 720)])
	add_child(near)
	var dust := CPUParticles2D.new()
	dust.position = Vector2(640.0, 360.0)
	dust.amount = 40
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700.0, 380.0)
	dust.direction = Vector2(1.0, -0.25)
	dust.spread = 25.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 10.0
	dust.initial_velocity_max = 35.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 5.0
	dust.color = Color(1.0, 0.9, 0.7, 0.35)
	add_child(dust)


# -------------------------------------------------------------------- screens

func _show_main() -> void:
	UiKit.clear(_content)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_content.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 80.0
	box.offset_top = -270.0
	box.offset_right = 620.0
	box.offset_bottom = 270.0

	var title := UiKit.label("WILD PAKISTAN", 70, Color(1.0, 0.93, 0.75))
	UiKit.outlined(title, 10)
	box.add_child(title)
	var sub := UiKit.label("The Last Wilderness", 32, Color(0.95, 0.8, 0.5))
	UiKit.outlined(sub, 6)
	box.add_child(sub)
	var tag := UiKit.label("Run. Hunt. Survive. Protect the wild.", 20, Color(0.85, 0.9, 0.85))
	UiKit.outlined(tag, 4)
	box.add_child(tag)
	box.add_child(Control.new())

	var last_a: String = _sel_animal
	var play := UiKit.button("PLAY NOW", _play_last, Vector2(380, 84))
	UiKit.accent_button(play)
	box.add_child(play)
	var pick := UiKit.button("Choose game mode", _show_modes, Vector2(380, 60))
	box.add_child(pick)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiKit.button("My Profile", _show_profile, Vector2(184, 54)))
	row.add_child(UiKit.button("Leaderboards", _show_boards, Vector2(184, 54)))
	box.add_child(row)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	row2.add_child(UiKit.button("Journal", _show_journal, Vector2(184, 50)))
	row2.add_child(UiKit.button("Settings", _show_settings, Vector2(184, 50)))
	box.add_child(row2)
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		box.add_child(UiKit.button("Quit", func() -> void: get_tree().quit(), Vector2(380, 50)))
	var stats: Dictionary = SaveManager.data["stats"]
	var ver := UiKit.label("Playing as %s   |   Best score %d   |   Coins %d" % [Animals.DB[last_a]["name"], int(stats.get("best_score", 0)), SaveManager.coins()], 16, Color(0.9, 0.9, 0.8))
	UiKit.outlined(ver, 4)
	box.add_child(ver)

	var i := 0
	for c in box.get_children():
		if c is Control:
			UiKit.intro(c, 0.1 * i)
		i += 1
	await get_tree().process_frame
	if is_instance_valid(play):
		UiKit.pulse(play)

	# live 3D animal on the right
	var prev := _make_preview(false)
	_content.add_child(prev)
	prev.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	prev.offset_left = -560.0
	prev.offset_right = -40.0
	prev.offset_top = -300.0
	prev.offset_bottom = 300.0
	UiKit.intro(prev, 0.4)


func _show_select() -> void:
	UiKit.clear(_content)
	_pivot = null
	_sel_biome = _fix_biome(_sel_biome)
	var cfg: Dictionary = Animals.DB[_sel_animal]
	var locked := not SaveManager.animal_unlocked(_sel_animal)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_content.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24.0
	root.offset_right = -24.0
	root.offset_top = 14.0
	root.offset_bottom = -14.0

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.add_child(UiKit.button("< Back", _show_main, Vector2(140, 52)))
	var heading := UiKit.label("Choose your animal and habitat", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	top.add_child(UiKit.label("Coins: %d" % SaveManager.coins(), 24, Color(1.0, 0.88, 0.4)))
	root.add_child(top)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	# ---- animal list
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.custom_minimum_size = Vector2(250, 0)
	for id in Animals.ORDER:
		var a: Dictionary = Animals.DB[id]
		var open := SaveManager.animal_unlocked(id)
		var text: String = a["name"] if open else "%s\nLocked: %d missions" % [a["name"], a["unlock_missions"]]
		var b := UiKit.button(text, func() -> void: _pick_animal(id), Vector2(250, 84))
		b.add_theme_font_size_override("font_size", 20)
		if id == _sel_animal:
			b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		list.add_child(b)
	body.add_child(list)

	# ---- 3D preview
	body.add_child(_make_preview(locked))

	# ---- details
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(info)
	body.add_child(scroll)

	info.add_child(UiKit.label(cfg["name"], 34, Color(1.0, 0.93, 0.75)))
	info.add_child(UiKit.label("%s  |  %s" % [cfg["latin"], cfg["status"]], 16, Color(0.8, 0.85, 0.75)))
	info.add_child(UiKit.label(cfg["desc"], 20))
	info.add_child(UiKit.label("Diet: %s   Speed: %.0f   Health: %.0f   Climb: %d deg" % [String(cfg["diet"]).capitalize(), cfg["run"], cfg["max_health"], int(cfg["climb_angle"])], 18, Color(0.85, 0.95, 0.8)))
	info.add_child(UiKit.label("Ability - %s: %s" % [cfg["ability_name"], cfg["ability_desc"]], 18))
	info.add_child(UiKit.label("Attack - %s" % cfg["attack_name"], 18))
	info.add_child(UiKit.label(cfg["fact"], 16, Color(0.8, 0.85, 0.9)))

	if not locked:
		info.add_child(UiKit.label("Coat", 20, Color(1.0, 0.88, 0.4)))
		info.add_child(_skin_row())
	info.add_child(UiKit.label("Habitat", 20, Color(1.0, 0.88, 0.4)))
	info.add_child(_biome_row())
	if AdManager.is_available():
		info.add_child(UiKit.button("Watch ad: +50 coins", _watch_ad_for_coins, Vector2(320, 50)))

	# START is pinned below the scrolling details so it can never be lost off-screen.
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	var go := UiKit.button("START GAME", func() -> void: GameState.start_game(_sel_animal, _sel_biome), Vector2(460, 76))
	UiKit.accent_button(go)
	go.disabled = locked or _sel_biome == ""
	bar.add_child(go)
	if locked:
		var need := UiKit.label("Complete %d missions to unlock (you have %d)." % [cfg["unlock_missions"], SaveManager.completed_count()], 18, Color(1.0, 0.7, 0.55))
		bar.add_child(need)
	root.add_child(bar)
	if not go.disabled:
		await get_tree().process_frame
		if is_instance_valid(go):
			UiKit.pulse(go)


func _make_preview(locked: bool) -> Control:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(380, 420)
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(380, 420)
	container.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.8)
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	light.light_energy = 1.2
	vp.add_child(light)

	_pivot = Node3D.new()
	vp.add_child(_pivot)
	var tint := Animals.skin_color(_sel_animal, _sel_skin)
	if locked:
		tint = Color(0.05, 0.05, 0.06)
	_pivot.add_child(AnimalModel.build(_sel_animal, tint))

	var spec: Dictionary = AnimalModel.SPECS[_sel_animal]
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.position = Vector3(0.0, float(spec["h"]) * 0.75, 2.0 + float(spec["len"]) * 1.6)
	cam.rotation_degrees = Vector3(-6.0, 0.0, 0.0)
	vp.add_child(cam)
	return container


func _skin_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var skins: Array = Animals.DB[_sel_animal]["skins"]
	for i in skins.size():
		var owned := SaveManager.owns_skin(_sel_animal, i)
		var price: int = Animals.SKIN_PRICES[i]
		var text: String = skins[i]["name"] if owned else "%s\n%d coins" % [skins[i]["name"], price]
		var b := UiKit.button(text, func() -> void: _pick_skin(i), Vector2(150, 70))
		b.add_theme_font_size_override("font_size", 16)
		if owned and i == _sel_skin:
			b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		b.disabled = (not owned) and SaveManager.coins() < price
		row.add_child(b)
	return row


func _biome_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var habitats: Array = Animals.DB[_sel_animal]["habitats"]
	for id in Biomes.ORDER:
		var b_cfg: Dictionary = Biomes.DB[id]
		var open := SaveManager.biome_unlocked(id)
		var fits := habitats.has(id)
		var text: String = b_cfg["name"]
		if not fits:
			text += "\n(not a habitat)"
		elif not open:
			text += "\nLocked: %d missions" % b_cfg["unlock_missions"]
		var b := UiKit.button(text, func() -> void: _pick_biome(id), Vector2(150, 84))
		b.add_theme_font_size_override("font_size", 15)
		b.disabled = not (fits and open)
		if id == _sel_biome:
			b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		row.add_child(b)
	return row


func _show_journal() -> void:
	UiKit.clear(_content)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_content.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40.0
	root.offset_right = -40.0
	root.offset_top = 16.0
	root.offset_bottom = -16.0
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.add_child(UiKit.button("< Back", _show_main, Vector2(140, 52)))
	top.add_child(UiKit.label("Journal", 34))
	root.add_child(top)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	var stats: Dictionary = SaveManager.data["stats"]
	col.add_child(UiKit.label("Missions completed: %d / %d    Best run: %d days    Total days: %d    Hunts: %d    Rescues: %d    Deaths: %d" % [
		SaveManager.completed_count(), MissionManager.MISSIONS.size(), int(stats.get("best_days", 0)),
		int(stats.get("total_days", 0)), int(stats.get("kills", 0)), int(stats.get("rescues", 0)), int(stats.get("deaths", 0))], 20, Color(1.0, 0.88, 0.4)))
	col.add_child(UiKit.label("Complete missions to unlock animals: Markhor (3), Snow Leopard (8), Himalayan Brown Bear (12) and habitats: Ziarat (2), Northern Mountains (6).", 18))

	for biome in ["thar", "ziarat", "northern", "any"]:
		var heading := "Anywhere" if biome == "any" else String(Biomes.DB[biome]["name"])
		col.add_child(UiKit.label(heading, 28, Color(1.0, 0.93, 0.75)))
		if biome != "any":
			col.add_child(UiKit.label(Biomes.DB[biome]["fact"], 16, Color(0.8, 0.85, 0.9)))
		for m in MissionManager.missions_for_biome(biome):
			var done: bool = MissionManager.completed.has(m["id"])
			var progress := ""
			if not done and int(m["target"]) > 1:
				progress = "  (%d/%d)" % [MissionManager.progress.get(m["id"], 0), m["target"]]
			var who := ""
			if m.has("diets"):
				who = "  [%s]" % ", ".join(m["diets"])
			elif m.has("animals"):
				who = "  [%s]" % ", ".join(m["animals"])
			elif m.has("min_climb"):
				who = "  [climbers]"
			col.add_child(UiKit.label("%s %s - %d coins%s%s" % ["[x]" if done else "[ ]", m["title"], m["reward"], progress, who], 18, Color(0.7, 0.95, 0.7) if done else Color(0.95, 0.95, 0.9)))


func _show_settings() -> void:
	UiKit.clear(_content)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	_content.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.offset_left = -430.0
	root.offset_right = 430.0
	root.offset_top = -250.0
	root.offset_bottom = 250.0
	root.add_child(UiKit.label("Settings", 38, Color(1, 1, 1), true))
	var panel := SettingsPanel.new()
	panel.allow_reset = true
	root.add_child(UiKit.panel(panel))
	var back := UiKit.button("< Back", _show_main, Vector2(200, 56))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(back)


# ------------------------------------------------------------ modes & records

func _play_last() -> void:
	var last := String(SaveManager.data.get("last_mode", "survive"))
	if last == "survive":
		GameState.start_game(_sel_animal, _sel_biome)
	else:
		GameState.start_game("ranger", String(SaveManager.data.get("last_biome", "thar")), last)


## Standard screen frame: returns the content column below a Back button and title.
func _screen(title: String, back: Callable) -> VBoxContainer:
	UiKit.clear(_content)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_content.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 50.0
	root.offset_right = -50.0
	root.offset_top = 18.0
	root.offset_bottom = -18.0
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.add_child(UiKit.button("< Back", back, Vector2(140, 52)))
	var l := UiKit.label(title, 36, Color(1.0, 0.93, 0.75))
	UiKit.outlined(l, 6)
	top.add_child(l)
	root.add_child(top)
	return root


func _mode_card(title: String, blurb: String, color: Color, callback: Callable) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.flat(color, 18, Color(1, 1, 1, 0.35)))
	card.custom_minimum_size = Vector2(340, 330)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	var t := UiKit.label(title, 30, Color(1, 1, 1), true)
	UiKit.outlined(t, 5)
	v.add_child(t)
	var b := UiKit.label(blurb, 18, Color(0.97, 0.97, 0.92), true)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(300, 150)
	v.add_child(b)
	var go := UiKit.button("PLAY", callback, Vector2(220, 60))
	UiKit.accent_button(go)
	go.add_theme_font_size_override("font_size", 26)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(go)
	return card


func _show_modes() -> void:
	var root := _screen("Choose how to play", _show_main)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	row.add_child(_mode_card("Wild Life", "Live as a wild animal. Eat, drink, hide, fight back and survive the seasons while poachers hunt.", Color(0.16, 0.3, 0.2, 0.92), _show_select))
	row.add_child(_mode_card("Ranger Patrol", "Become a wildlife ranger. Dart and arrest poachers, free trapped animals, remove snares. Lose too many animals and the patrol fails.", Color(0.28, 0.22, 0.1, 0.92), func() -> void: _show_ranger_select("ranger")))
	row.add_child(_mode_card("Photo Safari", "A peaceful ranger walk. Photograph rare wildlife, fill your field guide and earn photo ratings.", Color(0.12, 0.24, 0.34, 0.92), func() -> void: _show_ranger_select("safari")))
	var i := 0
	for c in row.get_children():
		UiKit.intro(c, 0.1 * i)
		i += 1


func _show_ranger_select(mode: String) -> void:
	var root := _screen("Ranger Patrol" if mode == "ranger" else "Photo Safari", _show_modes)
	root.add_child(UiKit.label("Rank: %s    XP: %d    Species discovered: %d / %d" % [Records.rank_name(), Records.xp(), Records.discovered_count(), Catalog.total_species()], 22, Color(1.0, 0.88, 0.4)))
	root.add_child(UiKit.label("Pick a habitat to patrol. Controls: DART (F) sedates a poacher, ACT (E) arrests him, PHOTO (C) takes a picture.", 18))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	for biome in Biomes.ORDER:
		var cfg: Dictionary = Biomes.DB[biome]
		var locked := not SaveManager.biome_unlocked(biome)
		var text := String(cfg["name"])
		if locked:
			text += "   (locked: %d missions)" % int(cfg["unlock_missions"])
		var b := UiKit.button(text + "   -   START", func() -> void: GameState.start_game("ranger", biome, mode), Vector2(700, 66))
		b.disabled = locked
		col.add_child(b)
		col.add_child(UiKit.label(cfg["desc"], 16, Color(0.85, 0.9, 0.9)))
	var lesson := UiKit.label(Catalog.random_lesson(), 18, Color(0.7, 1.0, 0.8))
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(lesson)


func _show_profile() -> void:
	var root := _screen("My Profile", _show_main)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	name_row.add_child(UiKit.label("Name:", 24))
	var edit := LineEdit.new()
	edit.text = Records.player_name()
	edit.max_length = 16
	edit.custom_minimum_size = Vector2(260, 48)
	edit.text_submitted.connect(func(t: String) -> void: Records.set_name_value(t))
	edit.focus_exited.connect(func() -> void: Records.set_name_value(edit.text))
	name_row.add_child(edit)
	col.add_child(name_row)

	col.add_child(UiKit.label("%s    (%d XP)" % [Records.rank_name(), Records.xp()], 30, Color(1.0, 0.88, 0.4)))
	var prog := Records.rank_progress()
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(500, 26)
	bar.max_value = maxf(float(prog["need"]), 1.0)
	bar.value = float(prog["have"]) if int(prog["need"]) > 0 else bar.max_value
	bar.show_percentage = false
	col.add_child(bar)
	if int(prog["need"]) > 0:
		col.add_child(UiKit.label("%d XP to %s" % [int(prog["need"]) - int(prog["have"]), prog["next"]], 18, Color(0.85, 0.9, 0.9)))

	var r: Dictionary = Records.rec()
	var s: Dictionary = SaveManager.data["stats"]
	var lines := [
		"Coins: %d" % SaveManager.coins(),
		"Best survival: %d days    Total days: %d    Deaths: %d" % [int(s.get("best_days", 0)), int(s.get("total_days", 0)), int(s.get("deaths", 0))],
		"Animals rescued: %d    Snares removed: %d    Poachers arrested: %d    Poachers driven off: %d" % [int(s.get("rescues", 0)), int(r.get("snares", 0)), int(r.get("arrests", 0)), int(r.get("poachers_defeated", 0))],
		"Photos taken: %d    Best photo: %d pts    Animals lost to poachers (all time): %d" % [int(r.get("photos", 0)), int(r.get("best_photo", 0)), int(r.get("poached_total", 0))],
		"Fastest rescue: %s    Best score: %d    Runs played: %d" % [("%.1f s" % float(r.get("fastest_rescue", 0.0))) if float(r.get("fastest_rescue", 0.0)) > 0.0 else "none yet", int(s.get("best_score", 0)), int(r.get("runs", 0))],
	]
	for t in lines:
		col.add_child(UiKit.label(t, 20))

	col.add_child(UiKit.label("Field Guide  (%d / %d discovered)" % [Records.discovered_count(), Catalog.total_species()], 28, Color(1.0, 0.93, 0.75)))
	var disc: Dictionary = Records.discovered()
	for id in Catalog.INFO:
		var info: Dictionary = Catalog.INFO[id]
		if disc.has(id):
			var stars := clampi(1 + int(disc[id]) / 25, 1, 5)
			col.add_child(UiKit.label("%s  [%s]   best photo %d pts (%s)" % [info["name"], info["status"], int(disc[id]), "*".repeat(stars)], 18, Color(0.85, 1.0, 0.85)))
			var f := UiKit.label(info["fact"], 15, Color(0.8, 0.85, 0.9))
			f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			f.custom_minimum_size = Vector2(760, 0)
			col.add_child(f)
		else:
			col.add_child(UiKit.label("???  Not discovered yet. Photograph it in Ranger or Safari mode.", 18, Color(0.6, 0.6, 0.65)))


func _show_boards() -> void:
	var root := _screen("Leaderboards", _show_main)
	var note := "Online board connected." if Records.online_enabled() else "Showing your personal bests. The global board turns on when an online server is configured (see docs/ONLINE_LEADERBOARD.md)."
	var nl := UiKit.label(note, 16, Color(0.85, 0.9, 0.9))
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(nl)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	root.add_child(scroll)
	for id in Records.BOARDS:
		var board_id: String = id
		var title := String(Records.BOARDS[board_id][0])
		var b := UiKit.button(title.replace("High Score - ", ""), func() -> void: _fill_board(body, board_id), Vector2(120, 46))
		b.add_theme_font_size_override("font_size", 15)
		tabs.add_child(b)
	_fill_board(body, "survival")


func _fill_board(body: VBoxContainer, board: String) -> void:
	UiKit.clear(body)
	var info: Array = Records.BOARDS[board]
	body.add_child(UiKit.label(String(info[0]), 28, Color(1.0, 0.93, 0.75)))
	var unit: String = info[2]
	if Records.online_enabled():
		body.add_child(UiKit.label("Global top 20 (loading...)", 18, Color(0.85, 0.9, 0.9)))
		Records.fetch_online(board, func(ok: bool, rows: Array) -> void:
			if not is_instance_valid(body):
				return
			UiKit.clear(body)
			body.add_child(UiKit.label(String(info[0]) + (" - Global" if ok else " - (offline, personal bests)"), 28, Color(1.0, 0.93, 0.75)))
			if ok:
				var rank := 1
				for row in rows:
					body.add_child(UiKit.label("%2d.  %-16s  %s %s" % [rank, row["name"], str(row["value"]), unit], 20))
					rank += 1
				if rows.is_empty():
					body.add_child(UiKit.label("No scores yet. Be the first!", 20))
			else:
				_fill_local(body, board, unit))
		return
	_fill_local(body, board, unit)


func _fill_local(body: VBoxContainer, board: String, unit: String) -> void:
	var list: Array = Records.local_board(board)
	if list.is_empty():
		body.add_child(UiKit.label("No scores yet. Play a run to set your first record!", 20))
	var rank := 1
	for e in list:
		body.add_child(UiKit.label("%2d.  %-16s  %s %s" % [rank, e["name"], str(e["value"]), unit], 20))
		rank += 1


# ------------------------------------------------------------------ choices

func _pick_animal(id: String) -> void:
	_sel_animal = id
	_sel_skin = SaveManager.equipped_skin(id)
	_show_select()


func _pick_skin(i: int) -> void:
	if not SaveManager.owns_skin(_sel_animal, i):
		if not SaveManager.buy_skin(_sel_animal, i, int(Animals.SKIN_PRICES[i])):
			return
	SaveManager.equip_skin(_sel_animal, i)
	_sel_skin = i
	_show_select()


func _pick_biome(id: String) -> void:
	_sel_biome = id
	_show_select()


func _watch_ad_for_coins() -> void:
	if not AdManager.reward_granted.is_connected(_on_ad_coins):
		AdManager.reward_granted.connect(_on_ad_coins, CONNECT_ONE_SHOT)
	AdManager.show_rewarded("coins")


func _on_ad_coins(kind: String) -> void:
	if kind == "coins":
		SaveManager.add_coins(50)
		_show_select()


## A habitat the selected animal can live in and the player has unlocked.
func _fix_biome(wanted: String) -> String:
	var habitats: Array = Animals.DB[_sel_animal]["habitats"]
	if habitats.has(wanted) and SaveManager.biome_unlocked(wanted):
		return wanted
	for id in Biomes.ORDER:
		if habitats.has(id) and SaveManager.biome_unlocked(id):
			return id
	return ""
