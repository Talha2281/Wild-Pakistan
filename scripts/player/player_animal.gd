class_name PlayerAnimal
extends CharacterBody3D
## Third-person playable animal. Stats, abilities, attacks and stealth values all
## come from Animals.DB[species_id]. Set species_id and skin_index BEFORE add_child().
##
## Stealth values the AI reads: noise_level, visibility_factor, tracks.

var species_id := "chinkara"
var skin_index := 0
var _dust: CPUParticles3D
var _was_air := false
var cfg: Dictionary = {}
var diet := "herbivore"
var is_predator := false

var camera_rig: CameraRig
var stats: SurvivalStats

## 0..1+: how loud the player is right now (hearing range multiplier).
var noise_level := 0.0
## Multiplier on how far enemies can see the player (cover lowers it).
var visibility_factor := 1.0
var slow_timer := 0.0
## Recent footprints: {"pos": Vector3, "t": float seconds}. Shikari follow these.
var tracks: Array[Dictionary] = []

var ability_cd_left := 0.0
var ability_time_left := 0.0
var attack_cd_left := 0.0
var stalking := false

var _cover_count := 0
var _shelter_count := 0
var _visual: Node3D
var _sensor: Area3D
var _idle_time := 0.0
var _step_timer := 0.0
var _track_timer := 0.0
var _prompt_timer := 0.0
var _last_prompt := ""
var _noise_boost := 0.0
var _noise_boost_time := 0.0
var _look_down_time := 0.0
var _impulse_time := 0.0
var _cd_emit := 0.0
var _prev: Dictionary = {}
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	cfg = Animals.get_cfg(species_id)
	diet = cfg["diet"]
	is_predator = cfg["predator"]
	add_to_group("player")
	GameState.player = self
	collision_layer = GameConst.LAYER_PLAYER
	collision_mask = GameConst.LAYER_TERRAIN
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(float(cfg["climb_angle"]))

	var cap := AnimalModel.capsule_size(species_id)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = cap.x
	capsule.height = cap.y
	shape.shape = capsule
	shape.position.y = cap.y * 0.5
	add_child(shape)

	if cfg.get("human", false):
		_visual = AnimalModel.build_ranger(Animals.skin_color(species_id, skin_index))
	else:
		_visual = AnimalModel.build(species_id, Animals.skin_color(species_id, skin_index))
	add_child(_visual)

	_dust = CPUParticles3D.new()
	_dust.amount = 18
	_dust.lifetime = 0.9
	_dust.emitting = false
	_dust.local_coords = false
	_dust.direction = Vector3(0, 1, 0)
	_dust.spread = 40.0
	_dust.initial_velocity_min = 0.4
	_dust.initial_velocity_max = 1.2
	_dust.gravity = Vector3(0, -0.4, 0)
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.1
	var dm := SphereMesh.new()
	dm.radius = 0.16
	dm.height = 0.3
	dm.radial_segments = 6
	dm.rings = 3
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.75, 0.68, 0.55, 0.45)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.material = dmat
	_dust.mesh = dm
	_dust.position.y = 0.1
	add_child(_dust)

	stats = SurvivalStats.new()
	stats.name = "SurvivalStats"
	add_child(stats)
	stats.configure(cfg)
	stats.died.connect(_on_died)

	_sensor = Area3D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = GameConst.LAYER_AREA
	_sensor.monitorable = false
	var sensor_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	sensor_shape.shape = sphere
	sensor_shape.position.y = 0.6
	_sensor.add_child(sensor_shape)
	add_child(_sensor)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	stats.ambient = GameState.ambient_temp
	stats.sheltered = _shelter_count > 0

	if stats.dead:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		if not is_on_floor():
			velocity.y -= _gravity * delta
		move_and_slide()
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := camera_rig.yaw if camera_rig else 0.0
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)
	var moving := input.length() > 0.1

	var jump_pressed := _just("jump")
	if _just("ability"):
		_use_ability()
	if _just("attack"):
		_do_attack()
	else:
		_auto_hunt()
	if _just("photo") and cfg.get("photographer", false):
		Photography.snap(self)

	var burst := ability_time_left > 0.0
	stats.boosted = burst
	var want_sprint := Input.is_action_pressed("sprint") and moving and not stalking and (stats.can_sprint() or burst)
	stats.sprinting = want_sprint and not burst
	var speed: float = cfg["walk"]
	if burst:
		speed = float(cfg["run"]) * 1.45
	elif want_sprint:
		speed = cfg["run"]
	elif stalking:
		speed = float(cfg["walk"]) * 0.6
	if moving:
		speed *= clampf(input.length(), 0.4, 1.0)
	if slow_timer > 0.0:
		speed *= 0.45
	speed *= GameConst.PACE

	if _impulse_time <= 0.0:
		var target := dir * speed
		velocity.x = move_toward(velocity.x, target.x, 25.0 * delta)
		velocity.z = move_toward(velocity.z, target.z, 25.0 * delta)

	if is_on_floor():
		if jump_pressed and stats.stamina > 10.0 and not stalking:
			velocity.y = cfg["jump"]
			stats.stamina -= 8.0
			AudioManager.play_3d("jump", global_position)
	else:
		velocity.y -= _gravity * delta

	var flat_speed := Vector2(velocity.x, velocity.z).length()
	if flat_speed > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), 9.0 * delta)

	move_and_slide()

	var limit := GameState.half_size - 3.0
	global_position.x = clampf(global_position.x, -limit, limit)
	global_position.z = clampf(global_position.z, -limit, limit)

	_update_stealth(moving, want_sprint or burst)
	_update_resting(moving, delta)
	_update_footsteps(moving, want_sprint or burst, delta)
	_update_tracks(moving, delta)
	_update_interaction(delta)
	PlaceholderModel.animate(_visual, flat_speed / float(cfg["run"]), delta, not is_on_floor())
	if _dust != null:
		_dust.emitting = is_on_floor() and flat_speed > float(cfg["run"]) * 0.55
	if is_on_floor() and _was_air:
		_visual.scale.y = 0.82          # landing squash, eased back below
		AudioManager.play_3d("step_grass", global_position, -2.0)
	_was_air = not is_on_floor()
	AnimalModel.pose_head(_visual, 1.0 if _look_down_time > 0.0 else (0.3 if stalking else 0.0), delta)
	_visual.scale.y = lerpf(_visual.scale.y, 0.78 if stalking else 1.0, clampf(delta * 8.0, 0.0, 1.0))


# --------------------------------------------------------------- public API

func hurt(amount: float) -> void:
	stats.take_damage(amount)


## Slows the player (net / snare).
func apply_net(duration: float) -> void:
	slow_timer = maxf(slow_timer, duration)


func enter_cover(shelter: bool) -> void:
	_cover_count += 1
	if shelter:
		_shelter_count += 1


func exit_cover(shelter: bool) -> void:
	_cover_count = maxi(0, _cover_count - 1)
	if shelter:
		_shelter_count = maxi(0, _shelter_count - 1)


func make_noise(level: float, duration: float) -> void:
	_noise_boost = level
	_noise_boost_time = duration


func look_down(duration: float) -> void:
	_look_down_time = duration


func is_sheltered() -> bool:
	return _shelter_count > 0


func revive() -> void:
	stats.revive(0.5)
	_visual.rotation_degrees.z = 0.0
	_visual.position.y = 0.0
	slow_timer = 0.0
	Events.player_revived.emit()


# ----------------------------------------------------------------- abilities

func _use_ability() -> void:
	var kind: String = cfg["ability"]
	if kind == "stealth":
		stalking = not stalking
		Events.toast.emit("Stalking: you move low and quiet." if stalking else "Stopped stalking.")
		return
	if ability_cd_left > 0.0:
		return
	match kind:
		"burst":
			ability_time_left = cfg["ability_time"]
			ability_cd_left = cfg["ability_cd"]
			AudioManager.play_3d("jump", global_position)
		"leap":
			if not is_on_floor():
				return
			var fwd := -global_transform.basis.z
			velocity = fwd * 13.0 + Vector3.UP * 9.5
			_impulse_time = 0.6
			ability_cd_left = cfg["ability_cd"]
			AudioManager.play_3d("jump", global_position)
		"roar":
			ability_cd_left = cfg["ability_cd"]
			AudioManager.play_3d("roar", global_position, 6.0, 0.02)
			make_noise(1.5, 3.0)
			for n in get_tree().get_nodes_in_group("animals"):
				var a := n as WildlifeAI
				if a != null and global_position.distance_to(a.global_position) < 20.0:
					a.scare(self, 6.0)
			for n in get_tree().get_nodes_in_group("shikari"):
				var s := n as ShikariAI
				if s != null and global_position.distance_to(s.global_position) < 18.0:
					s.scare(global_position, 8.0)


## Natural hunting: when prey (or, for herbivores, a predator) is close and in front,
## the animal lunges by itself - no button needed.
func _auto_hunt() -> void:
	if attack_cd_left > 0.0 or not is_on_floor() or _impulse_time > 0.0:
		return
	var kind: String = cfg["attack"]
	if kind == "tranq":
		return
	var fwd := -global_transform.basis.z
	var trigger: float = float(cfg["attack_range"]) + (3.5 if kind == "pounce" else 1.2)
	var best: WildlifeAI = null
	var best_d := trigger
	for n in get_tree().get_nodes_in_group("animals"):
		var a := n as WildlifeAI
		if a == null or a.dead:
			continue
		if diet == "herbivore" and not a.predator:
			continue
		var to := a.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d < best_d and d > 0.01 and fwd.dot(to / d) > 0.3:
			best_d = d
			best = a
	if best == null:
		return
	var tv := best.global_position - global_position
	rotation.y = atan2(-tv.x, -tv.z)
	_do_attack()
	if diet != "herbivore":
		velocity.y = maxf(velocity.y, 4.5)


func _do_attack() -> void:
	if attack_cd_left > 0.0:
		return
	attack_cd_left = cfg["attack_cd"]
	AudioManager.play_3d("swipe", global_position)
	var fwd := -global_transform.basis.z
	var kind: String = cfg["attack"]
	if kind == "pounce":
		velocity.x = fwd.x * 14.0
		velocity.z = fwd.z * 14.0
		velocity.y = 3.5
		_impulse_time = 0.35
	elif kind == "charge":
		velocity.x = fwd.x * 11.0
		velocity.z = fwd.z * 11.0
		_impulse_time = 0.3
	var reach: float = cfg["attack_range"]
	var dmg: float = cfg["attack_dmg"]
	if kind == "tranq":
		_fire_dart(reach, float(cfg["stun"]))
		return
	var cone := 0.45 if kind == "pounce" else 0.3
	var hit_any := false
	for n in get_tree().get_nodes_in_group("animals"):
		var a := n as WildlifeAI
		if a == null or a.dead:
			continue
		# Herbivores only defend themselves against predators.
		if diet == "herbivore" and not a.predator:
			continue
		var to := a.global_position - global_position
		to.y = 0.0
		if to.length() > reach or to.length() < 0.01:
			continue
		if fwd.dot(to.normalized()) < cone:
			continue
		hit_any = true
		if a.take_hit(dmg, self):
			SaveManager.bump_stat("kills")
			if diet != "herbivore" and not a.predator:
				Events.game_event.emit("hunt")
	var stun_time: float = cfg["stun"]
	for n in get_tree().get_nodes_in_group("shikari"):
		var s := n as ShikariAI
		if s == null:
			continue
		var to := s.global_position - global_position
		to.y = 0.0
		if to.length() <= reach and fwd.dot(to.normalized()) > cone:
			if stun_time > 0.0:
				s.stun(stun_time)
			s.take_hit(maxf(dmg, 1.0) * 10.0, self)
			hit_any = true
			Events.toast.emit("You hit the Shikari!")
	if hit_any:
		AudioManager.play_3d("hit", global_position + fwd * 1.5)


## Ranger dart gun: sedates the first poacher roughly in the line of fire.
func _fire_dart(reach: float, sedate_time: float) -> void:
	AudioManager.play_3d("gunshot", global_position, -6.0, 0.02)
	var fwd := -global_transform.basis.z
	if camera_rig != null:
		fwd = Vector3(-sin(camera_rig.yaw), 0.0, -cos(camera_rig.yaw))
	var best: ShikariAI = null
	var best_score := 0.82
	for n in get_tree().get_nodes_in_group("shikari"):
		var s := n as ShikariAI
		if s == null or s.sedated:
			continue
		var to := s.global_position - global_position
		var dist := to.length()
		if dist > reach or dist < 0.5:
			continue
		var facing := fwd.dot(Vector3(to.x, 0.0, to.z).normalized())
		if facing > best_score:
			best_score = facing
			best = s
	if best == null:
		Events.toast.emit("Dart missed. Aim toward the poacher (face him and fire).")
		return
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, best.global_position + Vector3.UP * 1.0, GameConst.LAYER_TERRAIN)
	if not space.intersect_ray(q).is_empty():
		Events.toast.emit("Dart blocked by terrain.")
		return
	best.sedate(sedate_time)


# ------------------------------------------------------------------ internals

func _just(action: String) -> bool:
	var now := Input.is_action_pressed(action)
	var was: bool = _prev.get(action, false)
	_prev[action] = now
	return now and not was


func _tick_timers(delta: float) -> void:
	slow_timer = maxf(0.0, slow_timer - delta)
	attack_cd_left = maxf(0.0, attack_cd_left - delta)
	_impulse_time = maxf(0.0, _impulse_time - delta)
	_look_down_time = maxf(0.0, _look_down_time - delta)
	_noise_boost_time = maxf(0.0, _noise_boost_time - delta)
	if ability_time_left > 0.0:
		ability_time_left = maxf(0.0, ability_time_left - delta)
	if ability_cd_left > 0.0:
		ability_cd_left = maxf(0.0, ability_cd_left - delta)
	_cd_emit -= delta
	if _cd_emit <= 0.0:
		_cd_emit = 0.1
		var total: float = cfg["ability_cd"]
		if total <= 0.0:
			Events.ability_cooldown.emit(1.0)
		else:
			Events.ability_cooldown.emit(1.0 - ability_cd_left / total)


func _update_stealth(moving: bool, sprinting: bool) -> void:
	noise_level = 1.0 if sprinting else (0.45 if moving else 0.05)
	if stalking:
		noise_level *= 0.35
	if _noise_boost_time > 0.0:
		noise_level = maxf(noise_level, _noise_boost)
	visibility_factor = 1.0
	if sprinting:
		visibility_factor = 1.3
	elif _cover_count > 0:
		visibility_factor = 0.35 if moving else 0.2
	if stalking:
		visibility_factor *= 0.5


func _update_resting(moving: bool, delta: float) -> void:
	_idle_time = 0.0 if moving else _idle_time + delta
	stats.resting = _idle_time > 1.5


func _update_footsteps(moving: bool, sprinting: bool, delta: float) -> void:
	if not moving or not is_on_floor():
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.3 if sprinting else (0.75 if stalking else 0.55)
		AudioManager.play_3d(GameState.step_sound, global_position, -12.0 if stalking else -6.0)


func _update_tracks(moving: bool, delta: float) -> void:
	_track_timer -= delta
	if moving and _track_timer <= 0.0:
		_track_timer = 0.8
		var now := Time.get_ticks_msec() / 1000.0
		tracks.append({"pos": global_position, "t": now})
		while tracks.size() > 0 and now - float(tracks[0]["t"]) > 25.0:
			tracks.pop_front()
		if tracks.size() > 40:
			tracks.pop_front()


func _update_interaction(delta: float) -> void:
	_prompt_timer -= delta
	var pressed := _just("interact")
	if _prompt_timer <= 0.0 or pressed:
		_prompt_timer = 0.2
		var target := _nearest_interactable()
		var text := ""
		if target != null:
			text = target.get_prompt(self)
		if text != _last_prompt:
			_last_prompt = text
			Events.prompt_changed.emit(text)
		if pressed and target != null:
			target.interact(self)


func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for a in _sensor.get_overlapping_areas():
		var it := a as Interactable
		if it == null or not it.can_interact(self):
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_d:
			best = it
			best_d = d
	return best


func _on_died() -> void:
	_visual.rotation_degrees.z = 90.0
	_visual.position.y = 0.3
	SaveManager.bump_stat("deaths")
	Events.player_died.emit()
