class_name SprintStrategy
extends MovementStrategy

func move(creature: Creature, target_position: Vector2, delta: float) -> void:
	if creature.creature_data == null:
		return
	var speed = creature.creature_data.base_speed * creature.creature_data.sprinting_multiplier
	_move_toward_with_speed(creature, target_position, delta, speed)
