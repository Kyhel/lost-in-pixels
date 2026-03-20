class_name DefaultStrategy
extends MovementStrategy

const ROTATION_DONE_THRESHOLD: float = 0.01  ## Radians; consider rotation complete below this

func move(creature: Creature, request: MovementRequest, delta: float) -> void:

	if creature.creature_data == null:
		return

	var k: Dictionary = _resolve_request_kinematics(creature, request)
	if not k["allow_translate"]:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return

	var move_goal: Vector2 = k["move_goal"]
	var dir: Vector2 = (move_goal - creature.global_position)
	if dir.length_squared() < 0.0001:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return
	dir = dir.normalized()
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
