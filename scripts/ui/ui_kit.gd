class_name UiKit
extends RefCounted
## Shared look for every menu and HUD element: one Theme with large, touch-friendly
## controls, plus small builders so screens stay short.

static var _theme: Theme


static func make_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 22
	t.set_font_size("font_size", "Label", 22)
	t.set_font_size("font_size", "Button", 24)
	t.set_color("font_color", "Label", Color(0.96, 0.95, 0.9))
	t.set_color("font_color", "Button", Color(0.97, 0.96, 0.92))
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.6))
	t.set_stylebox("normal", "Button", flat(Color(0.16, 0.2, 0.17, 0.92), 12, Color(0.55, 0.7, 0.45, 0.8)))
	t.set_stylebox("hover", "Button", flat(Color(0.24, 0.3, 0.24, 0.95), 12, Color(0.75, 0.9, 0.6, 1.0)))
	t.set_stylebox("pressed", "Button", flat(Color(0.34, 0.44, 0.3, 1.0), 12, Color(0.9, 1.0, 0.75, 1.0)))
	t.set_stylebox("disabled", "Button", flat(Color(0.12, 0.13, 0.12, 0.8), 12, Color(0.3, 0.3, 0.3, 0.6)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", flat(Color(0.05, 0.07, 0.06, 0.72), 14, Color(0.4, 0.5, 0.35, 0.5)))
	_theme = t
	return t


static func flat(color: Color, radius: int, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(2)
	return sb


static func button(text: String, callback: Callable, min_size := Vector2(220, 60)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.pressed.connect(func() -> void:
		AudioManager.play_ui("click", -6.0)
		callback.call())
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.create_tween().tween_property(b, "scale", Vector2(1.05, 1.05), 0.1))
	b.mouse_exited.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	return b


## Gentle looping "tap me" pulse. Call after the node is in the tree.
static func pulse(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2(1.07, 1.07), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


## Slide + fade a control in; delay staggers a column of elements.
static func intro(node: Control, delay := 0.0) -> void:
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.45)


static func accent_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_stylebox_override("normal", flat(Color(0.85, 0.42, 0.1, 1.0), 18, Color(1.0, 0.85, 0.4, 1.0)))
	b.add_theme_stylebox_override("hover", flat(Color(0.97, 0.55, 0.18, 1.0), 18, Color(1.0, 0.95, 0.6, 1.0)))
	b.add_theme_stylebox_override("pressed", flat(Color(0.7, 0.32, 0.06, 1.0), 18, Color(1.0, 0.95, 0.6, 1.0)))
	b.add_theme_stylebox_override("disabled", flat(Color(0.3, 0.2, 0.12, 0.8), 18, Color(0.4, 0.3, 0.2, 0.6)))


static func label(text: String, size := 22, color := Color(0.96, 0.95, 0.9), center := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func outlined(l: Label, outline := 6) -> void:
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)


static func panel(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(child)
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
