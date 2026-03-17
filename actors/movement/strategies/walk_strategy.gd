class_name WalkStrategy
extends MovementStrategy

func move(creature: Creature, target_position: Vector2, delta: float) -> void:
	if creature.creature_data == null:
		return
	_move_toward_with_speed(creature, target_position, delta, creature.creature_data.base_speed)
