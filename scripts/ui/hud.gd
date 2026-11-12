class_name HUD
extends CanvasLayer
## In-game UI, built in code (no scene to maintain): survival bars incl. temperature,
## clock/season/weather line, coins, missions, prompts, toasts, danger/hurt/temperature
## overlays, touch controls (stick + ACT/ATTACK/ABILITY/JUMP/RUN), pause menu and the
## game-over panel with optional rewarded-ad revive.

const BAR_COLORS := {
	"health": Color(0.86, 0.22, 0.2),
	"hunger": Color(0.93, 0.6, 0.2),
	"thirst": Color(0.25, 0.6, 0.9),
	"stamina": Color(0.4, 0.78, 0.35),
	"temp": Color(0.75, 0.75, 0.85),
}
const BAR_NAMES := {"health": "Health", "hunger": "Food", "thirst": "Water", "stamina": "Energy", "temp": "Temp"}

var env: EnvironmentController

var _root: Control
var _bars: Dictionary = {}
var _info_label: Label
var _coins_label: Label
var _mission_panel: PanelContainer
var _mission_label: Label
var _toast_label: Label
var _prompt_label: Label
var _danger_rect: ColorRect
var _hurt_rect: ColorRect
var _temp_rect: ColorRect
var _ability_button: ActionButton
var _pause_menu: Control
var _game_over: Control
var _game_over_title: Label
var _revive_button: Button
var _game_over_stats: Label
var _toast_tween: Tween
var _info_timer := 0.0
var _ranger_label: Label
var _flash: ColorRect
var _score_label: Label
var _combo_label: Label
var _popup_label: Label
var _popup_tween: Tween
var _score_shown := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.make_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_temp_rect = _make_overlay(Color(0.3, 0.5, 1.0, 0.0))
	_danger_rect = _make_overlay(Color(0.55, 0.0, 0.0, 0.0))
	_hurt_rect = _make_overlay(Color(1.0, 0.0, 0.0, 0.0))
	_build_stats()
	_build_top_center()
	_build_top_right()
	_build_score()
	_build_ranger_info()
	_build_messages()
	_build_touch_controls()
	_build_pause_menu()
	_build_game_over()

	Events.stats_changed.connect(_on_stats)
	Events.damaged.connect(_on_damaged)
	Events.player_died.connect(_on_died)
	Events.player_revived.connect(_on_revived)
	Events.danger_level_changed.connect(_on_danger)
	Events.prompt_changed.connect(_on_prompt)
	Events.toast.connect(_show_toast)
	Events.coins_changed.connect(_on_coins)
	Events.score_changed.connect(_on_score)
	Events.score_popup.connect(_on_popup)
	Events.missions_changed.connect(_refresh_missions)
	Events.ability_cooldown.connect(func(f: float) -> void: _ability_button.cooldown = f)
	_on_coins(SaveManager.coins())
	_refresh_missions()


func _process(delta: float) -> void:
	_info_timer -= delta
	if _info_timer <= 0.0 and env != null and is_instance_valid(env):
		_info_timer = 0.5
		_info_label.text = env.status_text()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _game_over.visible:
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------------- build

func _make_overlay(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r


func _build_stats() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(16, 12)
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	for key in ["health", "hunger", "thirst", "stamina", "temp"]:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := UiKit.label(BAR_NAMES[key], 16)
		label.custom_minimum_size = Vector2(64, 0)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(190, 16)
		bar.show_percentage = false
		bar.max_value = 100.0
		bar.value = 100.0 if key != "temp" else 50.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill := StyleBoxFlat.new()
		fill.bg_color = BAR_COLORS[key]
		fill.set_corner_radius_all(4)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.0, 0.0, 0.0, 0.45)
		back.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", back)
		row.add_child(label)
		row.add_child(bar)
		box.add_child(row)
		_bars[key] = bar


func _build_top_center() -> void:
	_info_label = UiKit.label("", 18, Color(1, 1, 1), true)
	UiKit.outlined(_info_label, 5)
	_info_label.anchor_right = 1.0
	_info_label.offset_top = 8.0
	_info_label.offset_bottom = 36.0
	_info_label.offset_left = 300.0
	_info_label.offset_right = -340.0
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_info_label)


func _build_top_right() -> void:
	_coins_label = UiKit.label("", 22, Color(1.0, 0.88, 0.4))
	UiKit.outlined(_coins_label, 5)
	_coins_label.anchor_left = 1.0
	_coins_label.anchor_right = 1.0
	_coins_label.offset_left = -330.0
	_coins_label.offset_right = -16.0
	_coins_label.offset_top = 8.0
	_coins_label.offset_bottom = 36.0
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_coins_label)

	var row := HBoxContainer.new()
	row.anchor_left = 1.0
	row.anchor_right = 1.0
	row.offset_left = -330.0
	row.offset_right = -12.0
	row.offset_top = 40.0
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	var missions_btn := UiKit.button("Missions", _toggle_missions, Vector2(150, 46))
	missions_btn.add_theme_font_size_override("font_size", 18)
	var pause_btn := UiKit.button("II", func() -> void: _set_paused(true), Vector2(70, 46))
	row.add_child(missions_btn)
	row.add_child(pause_btn)
	_root.add_child(row)

	_mission_panel = PanelContainer.new()
	_mission_panel.visible = false
	_mission_panel.anchor_left = 1.0
	_mission_panel.anchor_right = 1.0
	_mission_panel.offset_left = -340.0
	_mission_panel.offset_right = -12.0
	_mission_panel.offset_top = 94.0
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_label = UiKit.label("", 16)
	_mission_label.custom_minimum_size = Vector2(290, 0)
	_mission_panel.add_child(_mission_label)
	_root.add_child(_mission_panel)


func _build_ranger_info() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 1)
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Events.photo_flash.connect(func() -> void:
		_flash.modulate.a = 0.85
		create_tween().tween_property(_flash, "modulate:a", 0.0, 0.35))
	if GameState.mode == "survive":
		return
	_ranger_label = UiKit.label("", 20, Color(1.0, 0.85, 0.5))
	UiKit.outlined(_ranger_label, 5)
	_ranger_label.position = Vector2(20.0, 150.0)
	_ranger_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ranger_label)
	Events.game_event.connect(func(_e: String) -> void: _refresh_ranger())
	_refresh_ranger()


func _refresh_ranger() -> void:
	if _ranger_label == null:
		return
	var rec: Dictionary = Records.rec()
	var lost := "Animals lost: %d/%d\n" % [GameState.poached, GameState.POACH_LIMIT] if GameState.mode == "ranger" else ""
	_ranger_label.text = "%s%s  |  Arrests %d\nSpecies %d/%d" % [lost, Records.rank_name(), int(rec.get("arrests", 0)), Records.discovered_count(), Catalog.total_species()]


func _build_score() -> void:
	_score_label = UiKit.label("0", 40, Color(1.0, 0.92, 0.55), true)
	UiKit.outlined(_score_label, 8)
	_score_label.anchor_right = 1.0
	_score_label.offset_left = 300.0
	_score_label.offset_right = -340.0
	_score_label.offset_top = 34.0
	_score_label.offset_bottom = 84.0
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.pivot_offset = Vector2(250.0, 25.0)
	_root.add_child(_score_label)

	_combo_label = UiKit.label("", 26, Color(0.5, 1.0, 0.9), true)
	UiKit.outlined(_combo_label, 6)
	_combo_label.anchor_right = 1.0
	_combo_label.offset_left = 300.0
	_combo_label.offset_right = -340.0
	_combo_label.offset_top = 84.0
	_combo_label.offset_bottom = 118.0
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_combo_label)

	_popup_label = UiKit.label("", 28, Color(1, 1, 1), true)
	UiKit.outlined(_popup_label, 7)
	_popup_label.anchor_right = 1.0
	_popup_label.anchor_top = 0.5
	_popup_label.anchor_bottom = 0.5
	_popup_label.offset_top = -170.0
	_popup_label.offset_bottom = -130.0
	_popup_label.offset_left = 300.0
	_popup_label.offset_right = -300.0
	_popup_label.modulate.a = 0.0
	_popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_popup_label)


func _on_score(score: int, combo: int) -> void:
	_score_label.text = "%d" % score
	_combo_label.text = "COMBO x%d" % combo if combo > 1 else ""
	_score_label.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(_score_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_popup(text: String) -> void:
	_popup_label.text = text
	_popup_label.modulate.a = 1.0
	_popup_label.position.y = -170.0 + 0.0
	if _popup_tween != null:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup_label, "modulate:a", 0.0, 0.9).set_delay(0.25)


func _build_messages() -> void:
	_toast_label = UiKit.label("", 24, Color(1, 1, 1), true)
	UiKit.outlined(_toast_label, 6)
	_toast_label.anchor_right = 1.0
	_toast_label.offset_left = 120.0
	_toast_label.offset_right = -120.0
	_toast_label.offset_top = 80.0
	_toast_label.offset_bottom = 150.0
	_toast_label.modulate.a = 0.0
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_label)

	_prompt_label = UiKit.label("", 22, Color(1, 1, 1), true)
	UiKit.outlined(_prompt_label, 6)
	_prompt_label.anchor_top = 1.0
	_prompt_label.anchor_bottom = 1.0
	_prompt_label.anchor_right = 1.0
	_prompt_label.offset_top = -200.0
	_prompt_label.offset_bottom = -160.0
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_prompt_label)


func _build_touch_controls() -> void:
	var joy := VirtualJoystick.new()
	var joy_size := joy.radius * 2.0 + 40.0
	joy.anchor_top = 1.0
	joy.anchor_bottom = 1.0
	joy.offset_left = 30.0
	joy.offset_right = 30.0 + joy_size
	joy.offset_top = -30.0 - joy_size
	joy.offset_bottom = -30.0
	_root.add_child(joy)

	var cfg: Dictionary = Animals.get_cfg(GameState.animal_id)
	var attack_label := String(cfg["attack_name"]).split(" ")[0].to_upper()
	var ability_label := String(cfg["ability_name"]).split(" ")[-1].to_upper()
	_place_button("interact", "ACT", 112.0, 30.0, 30.0)
	_place_button("attack", attack_label, 96.0, 160.0, 40.0)
	_place_button("sprint", "RUN", 90.0, 270.0, 44.0)
	_place_button("jump", "JUMP", 88.0, 40.0, 150.0)
	_ability_button = _place_button("ability", ability_label, 92.0, 140.0, 150.0)
	if cfg.get("photographer", false):
		_place_button("photo", "PHOTO", 92.0, 240.0, 150.0)


func _place_button(action: StringName, text: String, s: float, margin_x: float, margin_y: float) -> ActionButton:
	var b := ActionButton.new()
	b.action = action
	b.label = text
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = -margin_x - s
	b.offset_right = -margin_x
	b.offset_top = -margin_y - s
	b.offset_bottom = -margin_y
	_root.add_child(b)
	return b


func _build_pause_menu() -> void:
	_pause_menu = Control.new()
	_pause_menu.visible = false
	_root.add_child(_pause_menu)
	_pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	_pause_menu.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_pause_menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	box.add_child(UiKit.label("Paused", 40, Color(1, 1, 1), true))
	var settings := SettingsPanel.new()
	box.add_child(UiKit.panel(settings))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(UiKit.button("Resume", func() -> void: _set_paused(false)))
	row.add_child(UiKit.button("Main Menu", func() -> void: GameState.go_menu()))
	box.add_child(row)


func _build_game_over() -> void:
	_game_over = Control.new()
	_game_over.visible = false
	_root.add_child(_game_over)
	_game_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	_game_over.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_game_over.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	_game_over_title = UiKit.label("", 26, Color(1, 1, 1), true)
	_game_over_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_game_over_title.custom_minimum_size = Vector2(760, 0)
	_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_game_over_title)
	_game_over_stats = UiKit.label("", 24, Color(1.0, 0.92, 0.55), true)
	box.add_child(_game_over_stats)
	_revive_button = UiKit.button("Revive (watch a short ad)", _on_revive_pressed, Vector2(380, 64))
	box.add_child(_revive_button)
	var again := UiKit.button("PLAY AGAIN", func() -> void: GameState.reload_level(), Vector2(380, 80))
	again.add_theme_font_size_override("font_size", 32)
	again.add_theme_stylebox_override("normal", UiKit.flat(Color(0.85, 0.45, 0.12, 1.0), 16, Color(1.0, 0.85, 0.4, 1.0)))
	again.add_theme_stylebox_override("hover", UiKit.flat(Color(0.95, 0.55, 0.18, 1.0), 16, Color(1.0, 0.95, 0.6, 1.0)))
	box.add_child(again)
	box.add_child(UiKit.button("Main Menu", func() -> void: GameState.go_menu(), Vector2(380, 60)))


# ------------------------------------------------------------------ handlers

func _on_stats(hunger: float, thirst: float, health: float, stamina: float, temp: float) -> void:
	_bars["hunger"].value = hunger
	_bars["thirst"].value = thirst
	_bars["health"].value = health
	_bars["stamina"].value = stamina
	_bars["temp"].value = temp
	var fill := (_bars["temp"] as ProgressBar).get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = Color(0.4, 0.6, 1.0) if temp < 40.0 else (Color(0.95, 0.5, 0.2) if temp > 60.0 else Color(0.75, 0.75, 0.85))
	var cold := clampf((35.0 - temp) / 35.0, 0.0, 1.0)
	var hot := clampf((temp - 65.0) / 35.0, 0.0, 1.0)
	if cold > hot:
		_temp_rect.color = Color(0.35, 0.55, 1.0, cold * 0.28)
	else:
		_temp_rect.color = Color(1.0, 0.55, 0.2, hot * 0.25)


func _on_damaged(_amount: float) -> void:
	_hurt_rect.color.a = 0.35
	create_tween().tween_property(_hurt_rect, "color:a", 0.0, 0.4)


func _on_danger(level: float) -> void:
	_danger_rect.color.a = level * 0.22


func _on_prompt(text: String) -> void:
	_prompt_label.text = "" if text.is_empty() else "ACT: " + text


func _on_coins(total: int) -> void:
	_coins_label.text = "Coins: %d" % total


func _refresh_missions() -> void:
	_mission_label.text = "Missions\n" + "\n".join(MissionManager.get_lines())


func _toggle_missions() -> void:
	_mission_panel.visible = not _mission_panel.visible


func _show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.6)


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_pause_menu.visible = value
	if value:
		for a in ["move_left", "move_right", "move_forward", "move_back", "sprint"]:
			Input.action_release(a)


func _on_died() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	var days := GameState.days_survived
	_game_over_title.text = "The wilderness claims another life.\nYou survived %d day%s." % [days, "" if days == 1 else "s"]
	if GameState.mode != "survive":
		var why := GameState.fail_reason if GameState.fail_reason != "" else "Patrol ended."
		_game_over_title.text = "%s\nRank: %s   |   Arrests %d\n%s" % [why, Records.rank_name(), int(Records.rec().get("arrests", 0)), Catalog.random_lesson()]
	GameState.bank_run()
	var earned := GameState.banked_coins
	var banner := ""
	if GameState.score > GameState.best_before and GameState.score > 0:
		banner = "NEW BEST!   "
	_game_over_stats.text = "%sScore %d   |   Best %d\nOrbs %d   |   +%d coins" % [banner, GameState.score, maxi(GameState.best_before, GameState.score), GameState.orbs, earned]
	AudioManager.play_ui("chime")
	_revive_button.visible = AdManager.is_available()
	_game_over.visible = true


func _on_revived() -> void:
	_game_over.visible = false


func _on_revive_pressed() -> void:
	_revive_button.disabled = true
	if not AdManager.reward_granted.is_connected(_on_ad_reward):
		AdManager.reward_granted.connect(_on_ad_reward, CONNECT_ONE_SHOT)
	AdManager.show_rewarded("revive")


func _on_ad_reward(kind: String) -> void:
	_revive_button.disabled = false
	if kind == "revive" and GameState.player != null and is_instance_valid(GameState.player):
		(GameState.player as PlayerAnimal).revive()
