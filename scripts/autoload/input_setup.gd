extends Node
## Registers keyboard actions in code so the project works the moment it is opened.
## Touch controls drive the same actions through Input.action_press().

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E],
	"jump": [KEY_SPACE],
	"attack": [KEY_F],
	"ability": [KEY_Q],
	"photo": [KEY_C],
	"pause": [KEY_ESCAPE, KEY_P],
}


func _enter_tree() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)
