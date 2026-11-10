class_name VirtualJoystick
extends Control
## On-screen movement stick. Drives the move_* input actions so the player
## script needs no touch-specific code. Reads touches in _input() so it works
## regardless of GUI focus, and marks them handled so the camera doesn't also
## treat them as a look-drag.

@export var radius := 90.0

var _touch := -1
var _vec := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _exit_tree() -> void:
	_release_all()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and get_global_rect().has_point(event.position):
			_touch = event.index
			_update(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch:
			_touch = -1
			_vec = Vector2.ZERO
			_release_all()
			queue_redraw()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch:
		_update(event.position)
		get_viewport().set_input_as_handled()


func _update(pos: Vector2) -> void:
	var center := get_global_rect().position + size * 0.5
	_vec = ((pos - center) / radius).limit_length(1.0)
	if _vec.length() < 0.15:
		_vec = Vector2.ZERO
	_press("move_left", maxf(-_vec.x, 0.0))
	_press("move_right", maxf(_vec.x, 0.0))
	_press("move_forward", maxf(-_vec.y, 0.0))
	_press("move_back", maxf(_vec.y, 0.0))
	queue_redraw()


func _press(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_all() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, radius, Color(0.0, 0.0, 0.0, 0.28))
	draw_arc(c, radius - 2.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.55), 3.0, true)
	draw_circle(c + _vec * radius * 0.7, radius * 0.38, Color(1.0, 1.0, 1.0, 0.5))
