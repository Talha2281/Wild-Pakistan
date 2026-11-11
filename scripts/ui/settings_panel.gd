class_name SettingsPanel
extends VBoxContainer
## Volume, camera sensitivity and graphics quality. Used by the main menu and the
## pause menu. Changes apply and save immediately.

var allow_reset := false

var _reset_armed := false
var _reset_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_add_slider("Master volume", "master", 0.0, 1.0, 0.05)
	_add_slider("Effects volume", "sfx", 0.0, 1.0, 0.05)
	_add_slider("Music volume", "music", 0.0, 1.0, 0.05)
	_add_slider("Ambience volume", "ambience", 0.0, 1.0, 0.05)
	_add_slider("Camera sensitivity", "sensitivity", 0.4, 2.0, 0.1)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiKit.label("Graphics (applies next game)", 20))
	var quality := OptionButton.new()
	quality.add_item("Low (fastest)", 0)
	quality.add_item("Medium", 1)
	quality.add_item("High", 2)
	quality.select(clampi(int(SaveManager.setting("quality")), 0, 2))
	quality.custom_minimum_size = Vector2(220, 50)
	quality.item_selected.connect(func(i: int) -> void: SaveManager.set_setting("quality", i))
	row.add_child(quality)
	add_child(row)

	if allow_reset:
		_reset_button = UiKit.button("Reset all progress", _on_reset, Vector2(280, 54))
		add_child(_reset_button)


func _add_slider(title: String, key: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := UiKit.label(title, 20)
	l.custom_minimum_size = Vector2(250, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(SaveManager.setting(key))
	s.custom_minimum_size = Vector2(300, 40)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void:
		SaveManager.data["settings"][key] = v
		AudioManager.apply_volumes())
	s.drag_ended.connect(func(_changed: bool) -> void: SaveManager.save_game())
	row.add_child(s)
	add_child(row)


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Tap again to erase everything"
		return
	_reset_armed = false
	_reset_button.text = "Progress erased"
	SaveManager.reset_progress()
	MissionManager.progress.clear()
	MissionManager.completed.clear()
	for m in MissionManager.MISSIONS:
		MissionManager.progress[m["id"]] = 0
