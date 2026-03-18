class_name RunStrategy
extends MovementStrategy

func move(creature: Creature, target_position: Vector2, delta: float, speed_desire: float) -> void:

	if creature.creature_data == null:
		return

	var max_speed = creature.creature_data.base_speed * creature.creature_data.running_multiplier
	var base_speed = creature.creature_data.base_speed

	var speed = lerp(base_speed, max_speed, speed_desire)

	_move_toward_with_speed(creature, target_position, delta, speed)
