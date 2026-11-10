class_name ShikariAI
extends CharacterBody3D
## Poacher AI. Patrols, notices the player by sight / sound / footprints,
## investigates, chases, and attacks with a net at close range or a rifle at
## distance (ranged = true). Retreats when beaten, can be stunned or scared off.
##
## States: PATROL -> LOOK_AROUND -> PATROL
##         suspicion -> INVESTIGATE -> (LOOK_AROUND | CHASE)
##         CHASE -> (lost: LOOK_AROUND) | (gave up / hit twice: RETREAT) -> PATROL
##
## Set patrol_points, ranged and position BEFORE add_child().

enum State { PATROL, LOOK_AROUND, INVESTIGATE, CHASE, RETREAT }

@export var patrol_speed := 2.4
@export var chase_speed := 7.0
@export var sight_range := 30.0
@export var sight_fov_deg := 110.0
@export var hearing_range := 16.0
@export var give_up_time := 22.0
@export var ranged := false

var patrol_points: Array[Vector3] = []
var shirt_color := Color(0.55, 0.5, 0.35)
var state: State = State.PATROL
## 0..1. At 1.0 the Shikari commits to a chase.
var awareness := 0.0
var last_known := Vector3.ZERO

var _player: PlayerAnimal
var _visual: Node3D
var _patrol_index := 0
var _target := Vector3.ZERO
var _home := Vector3.ZERO
var _state_time := 0.0
var _look_duration := 3.0
var _think_timer := 0.0
var _net_cd := 0.0
var _shot_cd := 0.0
var _aim_pause := 0.0
var _stun_time := 0.0
var _hits := 0
var _caught_this_chase := false
var _ignore_time := 0.0
var _last_track_time := 0.0
var _step_timer := 0.0
var _sidestep := 0.0
var _sidestep_dir := 1.0
var _stuck := 0.0
var _gravity := 9.8


func _ready() -> void:
	add_to_group("shikari")
	collision_layer = GameConst.LAYER_SHIKARI
	collision_mask = GameConst.LAYER_TERRAIN
	floor_snap_length = 0.6

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)

	_visual = AnimalModel.build_human(shirt_color, Color(0.7, 0.2, 0.15), ranged)
	add_child(_visual)

	_home = global_position
	if patrol_points.is_empty():
		patrol_points.append(_home)
	_target = patrol_points[0]
	_think_timer = randf() * 0.15


func _physics_process(delta: float) -> void:
	_net_cd = maxf(0.0, _net_cd - delta)
	_shot_cd = maxf(0.0, _shot_cd - delta)
	_aim_pause = maxf(0.0, _aim_pause - delta)
	_ignore_time = maxf(0.0, _ignore_time - delta)
	_stun_time = maxf(0.0, _stun_time - delta)

	if _stun_time > 0.0:
		_decel(delta)
		_apply_gravity(delta)
		move_and_slide()
		PlaceholderModel.animate(_visual, 0.0, delta)
		return

	_state_time += delta
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = 0.15
		_think(0.15)

	_run_state(delta)
	_apply_gravity(delta)
	move_and_slide()

	if GameState.terrain != null and global_position.y < GameState.terrain.min_height - 12.0:
		global_position = _home + Vector3.UP * 3.0
		velocity = Vector3.ZERO

	var flat_speed := Vector2(velocity.x, velocity.z).length()
	_update_footsteps(flat_speed, delta)
	PlaceholderModel.animate(_visual, flat_speed / chase_speed, delta)


## 0..1 for the danger monitor (audio mix + vignette).
func alert_level() -> float:
	match state:
		State.CHASE:
			return 1.0
		State.INVESTIGATE:
			return 0.45 + awareness * 0.3
		_:
			return awareness * 0.5


## Knocked senseless for a moment (markhor charge, bear swipe).
func stun(seconds: float) -> void:
	_stun_time = maxf(_stun_time, seconds)
	_net_cd = maxf(_net_cd, seconds)


## Frightened off (bear roar): runs home and ignores the player for a while.
func scare(_from: Vector3, seconds: float) -> void:
	awareness = 0.0
	_stun_time = maxf(_stun_time, 1.0)
	_set_state(State.RETREAT)
	_ignore_time = seconds


## Another Shikari spotted something: go and look.
func alert_to(pos: Vector3) -> void:
	if state == State.PATROL or state == State.LOOK_AROUND:
		_target = pos
		awareness = maxf(awareness, 0.5)
		_set_state(State.INVESTIGATE)


# ---------------------------------------------------------------- perception

func _think(dt: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as PlayerAnimal
		if _player == null:
			return

	if _player.stats.dead or _ignore_time > 0.0:
		awareness = maxf(0.0, awareness - dt)
		if _player.stats.dead and state == State.CHASE:
			_set_state(State.PATROL)
		return

	var vis := GameState.visibility_mult
	var to := _player.global_position - global_position
	var dist := to.length()
	var seen := _can_see(to, dist, vis)
	var heard := dist < hearing_range * _player.noise_level * lerpf(0.6, 1.0, vis)

	if seen:
		awareness += dt * clampf(1.6 - dist / sight_range, 0.35, 1.4)
		last_known = _player.global_position
	elif heard:
		awareness += dt * 0.35
		last_known = _player.global_position
	else:
		awareness -= dt * (0.12 if state == State.CHASE else 0.18)
	awareness = clampf(awareness, 0.0, 1.0)

	match state:
		State.PATROL, State.LOOK_AROUND:
			if awareness >= 1.0:
				_begin_chase()
			elif awareness >= 0.4:
				_target = last_known
				_set_state(State.INVESTIGATE)
				AudioManager.play_3d("shikari_whistle", global_position)
			elif _find_track():
				_set_state(State.INVESTIGATE)
		State.INVESTIGATE:
			if awareness >= 1.0:
				_begin_chase()
			elif seen or heard:
				_target = last_known
		State.CHASE:
			if seen or heard:
				_target = _player.global_position
			if awareness <= 0.0:
				_end_chase(true)
			elif _state_time > give_up_time:
				_end_chase(false)
				_set_state(State.RETREAT)


func _can_see(to: Vector3, dist: float, vis: float) -> bool:
	if dist > sight_range * _player.visibility_factor * vis:
		return false
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() > 0.01:
		var fwd := -global_transform.basis.z
		if fwd.dot(flat.normalized()) < cos(deg_to_rad(sight_fov_deg * 0.5)):
			return false
	return _has_los()


func _has_los() -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.6,
		_player.global_position + Vector3.UP * 0.6,
		GameConst.LAYER_TERRAIN)
	return space.intersect_ray(q).is_empty()


## Looks for a fresh footprint nearby that we have not followed yet.
func _find_track() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var max_age := 18.0 * GameState.track_life_mult
	var best_t := -1.0
	var best_pos := Vector3.ZERO
	for tr in _player.tracks:
		var t := float(tr["t"])
		if now - t > max_age or t <= _last_track_time:
			continue
		if global_position.distance_to(tr["pos"]) > 8.0:
			continue
		if t > best_t:
			best_t = t
			best_pos = tr["pos"]
	if best_t < 0.0:
		return false
	_last_track_time = best_t
	_target = best_pos
	return true


# ------------------------------------------------------------- state machine

func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	match s:
		State.LOOK_AROUND:
			_look_duration = 4.0
		State.RETREAT:
			_ignore_time = maxf(_ignore_time, 8.0)
			awareness = 0.0
			_target = _home


func _begin_chase() -> void:
	_set_state(State.CHASE)
	_hits = 0
	_caught_this_chase = false
	Events.toast.emit("A Shikari has spotted you! Run or hide!")
	AudioManager.play_3d("shikari_shout", global_position, 3.0)
	for n in get_tree().get_nodes_in_group("shikari"):
		var other := n as ShikariAI
		if other != null and other != self and global_position.distance_to(other.global_position) < 45.0:
			other.alert_to(_player.global_position)


func _end_chase(lost: bool) -> void:
	if not _caught_this_chase:
		Events.game_event.emit("shikari_lost")
		Events.toast.emit("You lost the Shikari.")
	if lost:
		_set_state(State.LOOK_AROUND)


func _run_state(delta: float) -> void:
	match state:
		State.PATROL:
			var pt := patrol_points[_patrol_index]
			_move_toward(pt, patrol_speed, delta)
			if _flat_dist(pt) < 1.5:
				_patrol_index = (_patrol_index + 1) % patrol_points.size()
				_set_state(State.LOOK_AROUND)
		State.LOOK_AROUND:
			_decel(delta)
			rotation.y += delta * 0.9
			if _state_time > _look_duration:
				_set_state(State.PATROL)
		State.INVESTIGATE:
			_move_toward(_target, patrol_speed * 1.5, delta)
			if _flat_dist(_target) < 1.5:
				if not _find_track():
					_set_state(State.LOOK_AROUND)
			elif _state_time > 20.0:
				_set_state(State.LOOK_AROUND)
		State.CHASE:
			if _aim_pause > 0.0:
				_decel(delta)
			else:
				_move_toward(_target, chase_speed, delta)
			_try_net()
			if ranged:
				_try_shoot()
		State.RETREAT:
			_move_toward(_home, patrol_speed * 1.4, delta)
			if _flat_dist(_home) < 2.0:
				_patrol_index = 0
				_set_state(State.PATROL)


func _try_net() -> void:
	if _player == null or _player.stats.dead or _net_cd > 0.0:
		return
	if global_position.distance_to(_player.global_position) > 2.0:
		return
	_net_cd = 3.0
	_hits += 1
	_caught_this_chase = true
	_player.hurt(15.0)
	_player.apply_net(2.0)
	AudioManager.play_3d("trap_snap", _player.global_position)
	Events.toast.emit("The Shikari's net hits you!")
	if _hits >= 2:
		_set_state(State.RETREAT)


func _try_shoot() -> void:
	if _player == null or _player.stats.dead or _shot_cd > 0.0:
		return
	var d := global_position.distance_to(_player.global_position)
	if d < 5.0 or d > 26.0 or not _has_los():
		return
	_shot_cd = 2.8
	_aim_pause = 0.7
	AudioManager.play_3d("gunshot", global_position, 4.0, 0.03)
	var chance := clampf(0.65 - d / 50.0, 0.12, 0.6)
	if _player.noise_level > 0.9:
		chance *= 0.6
	if _player.visibility_factor < 0.5:
		chance *= 0.5
	if randf() < chance:
		_caught_this_chase = true
		_player.hurt(14.0)
		Events.toast.emit("You've been shot!")
		AudioManager.play_3d("hit", _player.global_position)


# ------------------------------------------------------------------ steering

func _move_toward(dest: Vector3, speed: float, delta: float) -> void:
	var to := dest - global_position
	to.y = 0.0
	if to.length() < 0.1:
		_decel(delta)
		return
	var dir := to.normalized()
	if _sidestep > 0.0:
		_sidestep -= delta
		dir = dir.rotated(Vector3.UP, deg_to_rad(65.0) * _sidestep_dir)
	velocity.x = move_toward(velocity.x, dir.x * speed, 20.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 20.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 7.0 * delta)
	if is_on_wall():
		_stuck += delta
	else:
		_stuck = maxf(0.0, _stuck - delta)
	if _stuck > 0.5:
		_stuck = 0.0
		_sidestep = 0.8
		_sidestep_dir = 1.0 if randf() > 0.5 else -1.0


func _decel(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


func _update_footsteps(flat_speed: float, delta: float) -> void:
	if flat_speed < 0.5 or not is_on_floor():
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.62 if flat_speed < 4.0 else 0.34
		AudioManager.play_3d("step_human", global_position, -2.0)


func _flat_dist(p: Vector3) -> float:
	return Vector2(global_position.x - p.x, global_position.z - p.z).length()
