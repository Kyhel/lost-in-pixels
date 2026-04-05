class_name HopStrategy
extends MovementStrategy

var rest_duration: float = 0
var hop_duration: float = 0
var hop_ratio: float = 0

@export var rest_ratio: float = 0.5
@export var hop_base_duration: float = 0.7

var hop_timer: float = 0.0

func _init() -> void:
	hop_ratio = 1 - rest_ratio
	hop_duration = hop_base_duration * hop_ratio
	rest_duration = hop_base_duration * rest_ratio

func move(creature: Creature, request: MovementRequest, delta: float) -> void:

	if creature.creature_data == null:
		return

	hop_timer -= delta

	if hop_timer <= 0.0:
		hop_timer = hop_base_duration

	var max_speed = creature.creature_data.base_speed * creature.creature_data.running_multiplier
	var base_speed = creature.creature_data.base_speed
	var relative_speed = lerp(base_speed, max_speed, request.speed_desire)
	var hop_speed = relative_speed * creature.creature_data.hop_multiplier / hop_ratio

	if hop_timer < rest_duration:
		creature.velocity = Vector2.ZERO
		return

	_move_toward_with_speed(creature, request, delta, hop_speed)

func reset() -> void:
	hop_timer = 0.0
