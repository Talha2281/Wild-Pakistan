class_name ActionButton
extends Control
## Round on-screen button that holds an input action while touched.
## `cooldown` (0..1, 1 = ready) draws a sweep over the button for abilities.

@export var action: StringName = &"interact"
@export var label := "ACT"
## Toggle buttons stay on after one tap (needed on laptops, where a mouse can only press one thing at a time).
@export var toggle := false

var cooldown := 1.0:
	set(value):
		if absf(value - cooldown) > 0.01:
			cooldown = value
			queue_redraw()

var _touch := -1
var _down := false
var _press_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _exit_tree() -> void:
	if _down:
		Input.action_release(action)


func _input(event: InputEvent) -> void:
	# Touch and mouse both work. Browsers/laptops send a real mouse event AND an emulated
	# touch for one click, so the first press wins and the duplicate is ignored.
	var pos := Vector2.ZERO
	var pressed := false
	var idx := -2
	var is_btn := false
	if event is InputEventScreenTouch:
		is_btn = true
		pos = event.position
		pressed = event.pressed
		idx = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_btn = true
		pos = event.position
		pressed = event.pressed
	elif event is InputEventScreenDrag and event.index == _touch:
		get_viewport().set_input_as_handled()
		return
	if not is_btn:
		return
	if pressed:
		if _touch == -1 and _hit(pos):
			_touch = idx
			_set_down(true)
			get_viewport().set_input_as_handled()
	elif _touch != -1:
		_touch = -1
		_release()
		get_viewport().set_input_as_handled()


func _hit(pos: Vector2) -> bool:
	var rect := get_global_rect()
	var r := minf(rect.size.x, rect.size.y) * 0.5
	return pos.distance_to(rect.position + rect.size * 0.5) <= r * 1.1


func clear_toggle() -> void:
	if toggle and _down:
		_down = false
		Input.action_release(action)
		queue_redraw()


func _set_down(value: bool) -> void:
	if toggle:
		if not value:
			return
		value = not _down
	_down = value
	if value:
		_press_ms = Time.get_ticks_msec()
		Input.action_press(action)
	else:
		Input.action_release(action)
	queue_redraw()


## Keeps very short taps down for at least one physics tick so they are never missed.
func _release() -> void:
	if toggle:
		return
	var held := float(Time.get_ticks_msec() - _press_ms) / 1000.0
	if held < 0.12:
		await get_tree().create_timer(0.12 - held).timeout
	if _touch == -1:
		_set_down(false)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Color(0.0, 0.0, 0.0, 0.55 if _down else 0.32))
	if cooldown < 0.99:
		draw_arc(c, r * 0.5, -PI * 0.5, -PI * 0.5 + TAU * cooldown, 32, Color(1.0, 0.85, 0.3, 0.9), r, true)
	draw_arc(c, r - 2.0, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.7), 3.0, true)
	if toggle and _down:
		draw_arc(c, r - 6.0, 0.0, TAU, 40, Color(0.4, 1.0, 0.5, 0.95), 4.0, true)
	var font := ThemeDB.fallback_font
	var fs := 18
	var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	draw_string(font, c + Vector2(-ts.x * 0.5, ts.y * 0.25), label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color.WHITE)
