class_name DefaultStrategy
extends MovementStrategy

const ROTATION_DONE_THRESHOLD: float = 0.01  ## Radians; consider rotation complete below this

func move(creature: Creature, target_position: Vector2, delta: float, _speed_desire: float) -> void:

	if creature.creature_data == null:
		return

	var dir = (target_position - creature.global_position).normalized()
	var target_angle := dir.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta
	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	# if angle_diff_abs <= ROTATION_DONE_THRESHOLD:
	# 	creature.velocity = dir * walking_speed
	# 	return

	# var rotation_ratio = max(0, (PI - angle_diff_abs) / PI - 0.5)

	# creature.velocity = Vector2.from_angle(creature.rotation) * walking_speed * rotation_ratio
	creature.velocity = dir * creature.creature_data.base_speed
