class_name WildlifeAI
extends CharacterBody3D
## Reusable wildlife brain: one finite-state machine for prey, predators and
## territorial animals. Species stats come from Species.DB.
##
## Cost control for low-end phones:
##  - decisions ("thinking") run 3x per second and are staggered per animal
##  - per-frame work is steering + move_and_slide only
##  - no navmesh; steering is direct with simple stuck recovery
##
## Set the species fields and position BEFORE add_child(); the spawn point becomes home.

enum State { IDLE, WANDER, SEEK_FOOD, EAT, SEEK_WATER, DRINK, REST, FLEE, HUNT, FEED }

@export var species := "chinkara"
@export var predator := false
@export var diet := "herbivore"
@export var hp := 3.0
@export var walk_speed := 2.0
@export var run_speed := 7.0
@export var vision_range := 22.0
@export var hunts: PackedStringArray = PackedStringArray()
## Playable animal ids this animal attacks on sight.
@export var threat_to: PackedStringArray = PackedStringArray()
## Charges anything (except its own kind) that gets this close. 0 = never.
@export var territorial_radius := 0.0
@export var climb_angle := 46.0
@export var herd := false
@export var alert_sound := ""
@export var meat_value := 40.0
@export var wander_radius := 28.0

var state: State = State.IDLE
var home := Vector3.ZERO
var hunger := 80.0
var thirst := 80.0
var target_node: Node3D = null
var target_pos := Vector3.ZERO
## Read by the level's danger monitor to drive audio and the vignette.
var hunting_player := false
var dead := false

var _duration := 3.0
var _state_time := 0.0
var _think_timer := 0.0
var _attack_cd := 0.0
var _hunt_cd := 0.0
var _chase_lost := 0.0
var _stuck := 0.0
var _min_flee := 0.0
var _territory_hunt := false
var _shikari_hits := 0
var _visual: Node3D
var _player: PlayerAnimal
var _gravity := 9.8
var _slope_limit := 1.0


func _ready() -> void:
	add_to_group("animals")
	if predator:
		add_to_group("predators")
	collision_layer = GameConst.LAYER_ANIMAL
	collision_mask = GameConst.LAYER_TERRAIN
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(climb_angle)
	_slope_limit = tan(deg_to_rad(climb_angle * 0.8))

	var cap := AnimalModel.capsule_size(species)
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = cap.x
	capsule.height = cap.y
	cs.shape = capsule
	cs.position.y = cap.y * 0.5
	add_child(cs)

	_visual = AnimalModel.build(species)
	add_child(_visual)

	home = global_position
	hunger = randf_range(40.0, 90.0)
	thirst = randf_range(40.0, 90.0)
	_think_timer = randf() * 0.3
	_set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_state_time += delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_hunt_cd = maxf(0.0, _hunt_cd - delta)
	hunger = maxf(0.0, hunger - 0.35 * delta)
	thirst = maxf(0.0, thirst - 0.45 * delta)

	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = 0.3
		_think()
	_run_state(delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()

	var limit := GameState.half_size - 4.0
	global_position.x = clampf(global_position.x, -limit, limit)
	global_position.z = clampf(global_position.z, -limit, limit)
	if GameState.terrain != null and global_position.y < GameState.terrain.min_height - 12.0:
		global_position = home + Vector3.UP * 3.0
		velocity = Vector3.ZERO

	PlaceholderModel.animate(_visual, Vector2(velocity.x, velocity.z).length() / run_speed, delta)
	var head_down := state == State.EAT or state == State.DRINK or state == State.FEED
	AnimalModel.pose_head(_visual, 1.0 if head_down else 0.0, delta)


# ------------------------------------------------------------- public API

## Returns true if this blow killed the animal.
func take_hit(amount: float, attacker: Node3D) -> bool:
	if dead:
		return false
	hp -= amount
	if hp <= 0.0:
		die(attacker)
		return true
	target_node = attacker
	_hunt_cd = 15.0
	_min_flee = 3.5
	_set_state(State.FLEE)
	_alarm_herd(attacker)
	return false


func die(killer: Node3D) -> void:
	if dead:
		return
	dead = true
	remove_from_group("animals")
	remove_from_group("predators")
	var p := killer as PlayerAnimal
	if p != null and p.diet != "herbivore":
		Carcass.spawn(get_parent(), global_position, meat_value)
	AudioManager.play_3d("hit", global_position)
	queue_free()


## Scared by a roar etc.: run away from `from` for at least `seconds`.
func scare(from: Node3D, seconds: float) -> void:
	if dead:
		return
	target_node = from
	_min_flee = seconds
	_hunt_cd = maxf(_hunt_cd, seconds + 4.0)
	_set_state(State.FLEE)


## A herd member spotted danger.
func alarm(threat: Node3D) -> void:
	if dead or state == State.FLEE:
		return
	target_node = threat
	_set_state(State.FLEE)


# ---------------------------------------------------------------- decisions

func _think() -> void:
	var player := _get_player()
	var vis := GameState.visibility_mult
	if predator:
		if state == State.HUNT or state == State.FEED or state == State.FLEE:
			return
		if _defend_vs_shikari():
			return
		if _territory_check(player):
			return
		if _hunt_cd <= 0.0:
			var prey := _find_prey(player, vis)
			if prey != null:
				target_node = prey
				_set_state(State.HUNT)
				return
	else:
		var threat := _nearest_threat(player, vis)
		if threat != null:
			target_node = threat
			if state != State.FLEE:
				_min_flee = 0.0
				_set_state(State.FLEE)
				_alarm_herd(threat)
			return
		if state == State.FLEE:
			return

	if state == State.IDLE or state == State.WANDER or state == State.REST:
		if thirst < 35.0:
			_begin_seek(State.SEEK_WATER, &"water")
		elif hunger < 35.0 and diet != "carnivore":
			_begin_seek(State.SEEK_FOOD, &"food_plants")


## Strong animals fight back against poachers that come near.
func _defend_vs_shikari() -> bool:
	if _hunt_cd > 0.0:
		return false
	var best: ShikariAI = null
	var best_d := minf(vision_range * 0.6, 16.0)
	for n in get_tree().get_nodes_in_group("shikari"):
		var s := n as ShikariAI
		if s == null or s.sedated:
			continue
		var d := global_position.distance_to(s.global_position)
		if d < best_d:
			best_d = d
			best = s
	if best == null:
		return false
	target_node = best
	_territory_hunt = false
	_shikari_hits = 0
	_set_state(State.HUNT)
	return true


## Bears and similar: charge anything that wanders into their space.
func _territory_check(player: PlayerAnimal) -> bool:
	if territorial_radius <= 0.0 or _hunt_cd > 0.0 or player == null or player.stats.dead:
		return false
	if player.species_id == species:
		return false
	if global_position.distance_to(player.global_position) < territorial_radius:
		target_node = player
		_territory_hunt = true
		_set_state(State.HUNT)
		return true
	return false


func _begin_seek(seek_state: State, group: StringName) -> void:
	var node := _nearest_in_group(group, 90.0)
	if node != null:
		target_node = node
		_set_state(seek_state)


func _nearest_threat(player: PlayerAnimal, vis: float) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("predators"):
		var n3 := n as Node3D
		if n3 == null or n3 == self:
			continue
		var d := global_position.distance_to(n3.global_position)
		if d < vision_range * 0.6 * vis and d < best_d:
			best = n3
			best_d = d
	for n in get_tree().get_nodes_in_group("shikari"):
		var n3 := n as Node3D
		if n3 == null:
			continue
		var d := global_position.distance_to(n3.global_position)
		if d < vision_range * 0.8 * vis and d < best_d:
			best = n3
			best_d = d
	# A predator player is a threat too; stalking and cover make you harder to notice.
	if player != null and player.is_predator and not player.stats.dead:
		var dp := global_position.distance_to(player.global_position)
		if dp < vision_range * 0.55 * vis * player.visibility_factor and dp < best_d:
			best = player
	return best


func _find_prey(player: PlayerAnimal, vis: float) -> Node3D:
	var best: Node3D = null
	var best_d := vision_range * vis
	if hunger < 80.0:
		for n in get_tree().get_nodes_in_group("animals"):
			var a := n as WildlifeAI
			if a == null or a == self or a.dead or a.predator:
				continue
			if not hunts.has(a.species):
				continue
			var d := global_position.distance_to(a.global_position)
			if d < best_d:
				best = a
				best_d = d
	if player != null and not player.stats.dead and threat_to.has(player.species_id):
		var dp := global_position.distance_to(player.global_position)
		if dp < vision_range * vis * player.visibility_factor:
			best = player
	return best


func _nearest_in_group(group: StringName, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for n in get_tree().get_nodes_in_group(group):
		var n3 := n as Node3D
		if n3 == null or n3 == self or n3.get("available") == false:
			continue
		var d := global_position.distance_to(n3.global_position)
		if d < best_d:
			best = n3
			best_d = d
	return best


func _alarm_herd(threat: Node3D) -> void:
	if not herd:
		return
	for n in get_tree().get_nodes_in_group("animals"):
		var a := n as WildlifeAI
		if a != null and a != self and a.species == species and global_position.distance_to(a.global_position) < 28.0:
			a.alarm(threat)


func _get_player() -> PlayerAnimal:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as PlayerAnimal
	return _player


# ------------------------------------------------------------- state machine

func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	hunting_player = false
	_chase_lost = 0.0
	match s:
		State.IDLE:
			_duration = randf_range(2.0, 6.0)
		State.WANDER:
			target_pos = _random_point()
			_duration = 14.0
		State.EAT, State.DRINK:
			_duration = 3.0
		State.REST:
			_duration = randf_range(4.0, 8.0)
		State.FEED:
			_duration = 6.0
		State.FLEE, State.HUNT:
			if alert_sound != "":
				AudioManager.play_3d(alert_sound, global_position, 2.0)


func _run_state(delta: float) -> void:
	match state:
		State.IDLE, State.REST:
			_stand(delta)
			if _state_time > _duration:
				_set_state(State.WANDER if state == State.IDLE else State.IDLE)
		State.WANDER:
			_move_toward(target_pos, walk_speed, delta)
			if _flat_dist(target_pos) < 1.5 or _state_time > _duration:
				_set_state(State.IDLE)
		State.SEEK_FOOD, State.SEEK_WATER:
			if not _target_valid() or _state_time > 30.0:
				_set_state(State.IDLE)
				return
			_move_toward(target_node.global_position, walk_speed, delta)
			if _flat_dist(target_node.global_position) < (1.4 if state == State.SEEK_FOOD else 2.5):
				_set_state(State.EAT if state == State.SEEK_FOOD else State.DRINK)
		State.EAT:
			_stand(delta)
			if _state_time > _duration:
				hunger = minf(100.0, hunger + 45.0)
				if _target_valid() and target_node.has_method("npc_consume"):
					target_node.call("npc_consume")
				_set_state(State.IDLE)
		State.DRINK:
			_stand(delta)
			if _state_time > _duration:
				thirst = 100.0
				_set_state(State.IDLE)
		State.FEED:
			_stand(delta)
			if _state_time > _duration:
				_set_state(State.REST)
		State.FLEE:
			_run_flee(delta)
		State.HUNT:
			_run_hunt(delta)


func _run_flee(delta: float) -> void:
	if not _target_valid():
		_set_state(State.IDLE)
		return
	var away := global_position - target_node.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
	# Zig-zag so the escape looks alive, and turn home near the map edge.
	var dir := away.normalized().rotated(Vector3.UP, sin(_state_time * 2.5) * 0.5)
	var dest := global_position + dir * 10.0
	var edge := GameState.half_size - 10.0
	if absf(global_position.x) > edge or absf(global_position.z) > edge:
		dest = home
	_move_toward(dest, run_speed, delta)
	var done_time := maxf(3.0, _min_flee)
	if _state_time > done_time and (away.length() > vision_range * 1.1 or predator):
		_set_state(State.IDLE)


func _run_hunt(delta: float) -> void:
	if not _target_valid():
		_end_hunt(false)
		return
	var d := global_position.distance_to(target_node.global_position)
	if target_node is ShikariAI and (target_node as ShikariAI).sedated:
		_end_hunt(false)
		return
	_move_toward(target_node.global_position, run_speed, delta)

	var player := target_node as PlayerAnimal
	if player != null:
		hunting_player = true
		if player.stats.dead:
			_end_hunt(false)
			return
		var vis := GameState.visibility_mult
		if _territory_hunt:
			if d > territorial_radius * 2.4 or _state_time > 12.0:
				_end_hunt(false)
				return
		else:
			# Hiding works: out of (cover-reduced) sight for 4 s and the hunter loses you.
			if d > vision_range * vis * player.visibility_factor:
				_chase_lost += delta
			else:
				_chase_lost = 0.0
			if _chase_lost > 4.0 or d > vision_range * 1.6 or _state_time > 25.0:
				_end_hunt(true)
				return
	elif d > vision_range * 1.6 or _state_time > 20.0:
		_end_hunt(false)
		return

	if d < 1.9 and _attack_cd <= 0.0:
		_attack(target_node)


func _attack(t: Node3D) -> void:
	_attack_cd = 1.4
	if t is PlayerAnimal:
		(t as PlayerAnimal).hurt(6.0 + hp * 1.4)
		AudioManager.play_3d("hit", t.global_position)
		if _territory_hunt:
			# A warning swipe, not a kill: back off and cool down.
			_end_hunt(false)
	elif t is ShikariAI:
		(t as ShikariAI).take_hit(16.0 + hp * 3.0, self)
		AudioManager.play_3d("hit", t.global_position)
		_shikari_hits += 1
		if _shikari_hits >= 3:
			_end_hunt(false)
	elif t is WildlifeAI:
		(t as WildlifeAI).die(self)
		hunger = minf(100.0, hunger + 50.0)
		hunting_player = false
		_set_state(State.FEED)


func _end_hunt(player_escaped: bool) -> void:
	if player_escaped:
		Events.game_event.emit("chase_escaped")
		Events.toast.emit("You escaped the %s!" % species.replace("_", " "))
	_territory_hunt = false
	_hunt_cd = 12.0
	_set_state(State.REST)


# ------------------------------------------------------------------ steering

func _move_toward(dest: Vector3, speed: float, delta: float) -> void:
	var to := dest - global_position
	to.y = 0.0
	if to.length() < 0.05:
		_stand(delta)
		return
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, 18.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 18.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 8.0 * delta)
	if is_on_wall():
		_stuck += delta
	else:
		_stuck = maxf(0.0, _stuck - delta)
	if _stuck > 1.2:
		_stuck = 0.0
		if state == State.WANDER:
			target_pos = _random_point()


func _stand(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)


func _random_point() -> Vector3:
	var limit := GameState.half_size - 6.0
	var p := home
	for i in 6:
		var angle := randf() * TAU
		var dist := randf_range(5.0, wander_radius)
		p = home + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		p.x = clampf(p.x, -limit, limit)
		p.z = clampf(p.z, -limit, limit)
		if GameState.terrain == null or GameState.terrain.slope_at(p.x, p.z) < _slope_limit:
			break
	return p


func _flat_dist(p: Vector3) -> float:
	return Vector2(global_position.x - p.x, global_position.z - p.z).length()


func _target_valid() -> bool:
	return target_node != null and is_instance_valid(target_node)
