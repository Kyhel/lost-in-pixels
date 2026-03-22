class_name RunStrategy
extends MovementStrategy

func move(creature: Creature, request: MovementRequest, delta: float) -> void:

	if creature.creature_data == null:
		return

	var max_speed = creature.creature_data.base_speed * creature.creature_data.running_multiplier
	var base_speed = creature.creature_data.base_speed

	var speed = lerp(base_speed, max_speed, request.speed_desire)

	_move_toward_with_speed(creature, request, delta, speed)
