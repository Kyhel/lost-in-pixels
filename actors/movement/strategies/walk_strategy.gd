class_name WalkStrategy
extends MovementStrategy

func move(creature: Creature, target_position: Vector2, delta: float) -> void:

	if creature.creature_data == null:
		return

	var dir = (target_position - creature.global_position).normalized()
	var target_angle := dir.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta
	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	creature.velocity = dir * creature.creature_data.base_speed
