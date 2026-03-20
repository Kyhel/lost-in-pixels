class_name WanderAction
extends BTNode

@export var wander_radius: float = 200.0

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		target_position = pick_wander_target(creature)

		if not validate_target_position(creature, target_position):
			# retry once
			target_position = pick_wander_target(creature)
			if not validate_target_position(creature, target_position):
				# give up
				target_position = null
				return State.RUNNING
		
		creature.movement.request_movement(MovementRequest.to_world_position(target_position, 0.0))

	if creature.global_position.distance_to(target_position) < 15:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING

func validate_target_position(creature: Creature, _target_position: Vector2) -> bool:
	return ChunkManager.is_area_walkable_for_creature(
			creature, _target_position, creature.creature_data.hitbox_size
		) and not ChunkManager.is_environment_blocking_creature(creature, _target_position)

func pick_wander_target(creature: Creature) -> Vector2:

	var target_angle = PI * pow(randf(), 5) * signf(randf() - 0.5)

	var target_rotation_vector = Vector2.from_angle(target_angle + creature.rotation)

	var wander_distance = (randf() + 1) / 2 * wander_radius;

	return creature.global_position + target_rotation_vector * wander_distance
