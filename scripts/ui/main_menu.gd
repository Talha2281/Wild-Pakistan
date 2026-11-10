extends Control
## Main menu: title, animal + habitat selection (with a rotating 3D preview, skins
## and unlock requirements), journal (missions and stats) and settings.
## Built entirely in code; screens are rebuilt whenever a choice changes.

var _content: Control
var _sel_animal := "chinkara"
var _sel_skin := 0
var _sel_biome := "thar"
var _pivot: Node3D


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
	_show_main()


func _process(delta: float) -> void:
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
	far.color = Color(0.22, 0.25, 0.36)
	far.polygon = PackedVector2Array([Vector2(-400, 720), Vector2(-400, 520), Vector2(80, 420), Vector2(260, 500), Vector2(520, 330), Vector2(760, 470), Vector2(980, 380), Vector2(1250, 500), Vector2(1680, 400), Vector2(1680, 720)])
	add_child(far)
	var near := Polygon2D.new()
	near.color = Color(0.12, 0.1, 0.1)
	near.polygon = PackedVector2Array([Vector2(-400, 720), Vector2(-400, 640), Vector2(200, 600), Vector2(600, 650), Vector2(1000, 610), Vector2(1400, 650), Vector2(1680, 620), Vector2(1680, 720)])
	add_child(near)


# -------------------------------------------------------------------- screens

func _show_main() -> void:
	UiKit.clear(_content)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_content.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 90.0
	box.offset_top = -230.0
	box.offset_right = 600.0
	box.offset_bottom = 230.0

	var title := UiKit.label("WILD PAKISTAN", 64, Color(1.0, 0.93, 0.75))
	UiKit.outlined(title, 8)
	box.add_child(title)
	var sub := UiKit.label("The Last Wilderness", 30, Color(0.9, 0.85, 0.7))
	UiKit.outlined(sub, 6)
	box.add_child(sub)
	box.add_child(Control.new())
	box.add_child(UiKit.button("Play", _show_select, Vector2(320, 68)))
	box.add_child(UiKit.button("Journal", _show_journal, Vector2(320, 60)))
	box.add_child(UiKit.button("Settings", _show_settings, Vector2(320, 60)))
	if not OS.has_feature("mobile"):
		box.add_child(UiKit.button("Quit", func() -> void: get_tree().quit(), Vector2(320, 60)))
	var ver := UiKit.label("v%s  |  Coins: %d" % [GameConst.GAME_VERSION, SaveManager.coins()], 16, Color(0.85, 0.85, 0.8))
	UiKit.outlined(ver, 4)
	box.add_child(ver)


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

	var go := UiKit.button("START", func() -> void: GameState.start_game(_sel_animal, _sel_biome), Vector2(340, 72))
	go.disabled = locked or _sel_biome == ""
	info.add_child(go)
	if locked:
		info.add_child(UiKit.label("Complete %d missions to unlock (you have %d)." % [cfg["unlock_missions"], SaveManager.completed_count()], 18, Color(1.0, 0.6, 0.5)))


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
