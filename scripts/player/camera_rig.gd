class_name CameraRig
extends Node3D
## Third-person orbit camera. Drag any part of the screen not covered by a touch
## control to look. `yaw` is read by the player so movement is camera-relative.

@export var target: Node3D
@export var distance := 6.5
@export var height := 1.6
@export var follow_speed := 10.0

var yaw := 0.0
var pitch := deg_to_rad(-18.0)
var camera: Camera3D

var _arm: SpringArm3D
var _sensitivity := 0.006


func configure(dist: float, h: float) -> void:
	distance = dist
	height = h


func _ready() -> void:
	_sensitivity = 0.006 * float(SaveManager.setting("sensitivity"))
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.margin = 0.4
	_arm.collision_mask = GameConst.LAYER_TERRAIN
	add_child(_arm)

	camera = Camera3D.new()
	camera.fov = 70.0
	camera.far = 260.0
	camera.current = true
	_arm.add_child(camera)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var goal := target.global_position + Vector3(0.0, height, 0.0)
	global_position = global_position.lerp(goal, clampf(follow_speed * delta, 0.0, 1.0))
	rotation.y = yaw
	_arm.rotation.x = pitch


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		yaw -= event.relative.x * _sensitivity
		pitch = clampf(pitch - event.relative.y * _sensitivity, deg_to_rad(-65.0), deg_to_rad(-3.0))
