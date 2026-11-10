class_name SurvivalStats
extends Node
## Hunger / thirst / health / stamina / body temperature.
## Hunger, thirst and stamina are 0..100. Health is 0..max_health.
## temp_offset: 0 is comfortable, negative is cold, positive is hot. Beyond +-35 you
## take damage. Each animal has its own comfort range (Animals.DB "comfort").

signal died

var max_health := 100.0
var hunger_rate := 0.55
var thirst_rate := 0.8
var stamina_drain := 20.0
var stamina_regen := 12.0
var comfort_lo := 6.0
var comfort_hi := 40.0

var hunger := 100.0
var thirst := 100.0
var health := 100.0
var stamina := 100.0
var temp_offset := 0.0
var sprinting := false
var boosted := false
var resting := false
var dead := false
## Set every frame by the player from the world.
var ambient := 25.0
var sheltered := false

var _exhausted := false
var _emit_timer := 0.0


func configure(cfg: Dictionary) -> void:
	max_health = cfg["max_health"]
	health = max_health
	hunger_rate = cfg["hunger_rate"]
	thirst_rate = cfg["thirst_rate"]
	stamina_drain = cfg["stamina_drain"]
	comfort_lo = cfg["comfort"][0]
	comfort_hi = cfg["comfort"][1]


func _process(delta: float) -> void:
	if dead:
		return
	var is_sprinting := sprinting and not _exhausted
	var burn := 1.6 if is_sprinting else (0.6 if resting else 1.0)
	burn *= 1.0 + maxf(-temp_offset, 0.0) / 100.0   # cold burns energy
	hunger = maxf(0.0, hunger - hunger_rate * burn * delta)
	thirst = maxf(0.0, thirst - thirst_rate * burn * (1.0 + maxf(temp_offset, 0.0) / 80.0) * delta)

	if is_sprinting:
		stamina = maxf(0.0, stamina - stamina_drain * delta)
		if stamina <= 0.0:
			_exhausted = true
	elif not boosted:
		var regen := stamina_regen * (2.0 if resting else 1.0)
		if hunger < 20.0 or thirst < 20.0:
			regen *= 0.4
		stamina = minf(100.0, stamina + regen * delta)
		if _exhausted and stamina >= 25.0:
			_exhausted = false

	# Temperature drifts toward what the weather and season push it to.
	var mid := (comfort_lo + comfort_hi) * 0.5
	var half := maxf((comfort_hi - comfort_lo) * 0.5, 1.0)
	var target := clampf((ambient - mid) / half * 35.0, -55.0, 55.0)
	if sheltered:
		target *= 0.35
	temp_offset = move_toward(temp_offset, target, 3.0 * delta)
	var excess := maxf(absf(temp_offset) - 35.0, 0.0)
	if excess > 0.0:
		take_damage(excess * 0.15 * delta)

	if hunger <= 0.0 or thirst <= 0.0:
		take_damage(2.0 * delta)
	elif hunger > 40.0 and thirst > 40.0 and absf(temp_offset) < 30.0 and health < max_health:
		health = minf(max_health, health + (3.0 if resting else 1.0) * delta)

	_emit_timer += delta
	if _emit_timer >= 0.1:
		_emit_timer = 0.0
		Events.stats_changed.emit(hunger, thirst, health / max_health * 100.0, stamina, clampf(50.0 + temp_offset, 0.0, 100.0))


func can_sprint() -> bool:
	return not _exhausted and stamina > 0.0


func eat(amount: float) -> void:
	hunger = minf(100.0, hunger + amount)


func drink(amount: float) -> void:
	thirst = minf(100.0, thirst + amount)


func take_damage(amount: float) -> void:
	if dead:
		return
	health = maxf(0.0, health - amount)
	if amount >= 1.0:
		Events.damaged.emit(amount)
	if health <= 0.0:
		dead = true
		died.emit()


func revive(fraction: float) -> void:
	dead = false
	health = max_health * fraction
	hunger = maxf(hunger, 50.0)
	thirst = maxf(thirst, 50.0)
	stamina = 100.0
	temp_offset = 0.0
	_exhausted = false
