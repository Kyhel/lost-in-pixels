class_name WanderAction
extends BTNode

@export var wander_radius: float = 100.0

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		target_position = pick_wander_target(creature)

		if not ChunkManager.is_walkable(target_position):
			# retry once
			target_position = pick_wander_target(creature)
			if not ChunkManager.is_walkable(target_position):
				# give up
				target_position = null
				return State.RUNNING
		
		creature.movement.move_to(target_position)

	if creature.global_position.distance_to(target_position) < 10:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING


func pick_wander_target(creature: Creature) -> Vector2:

	var target_angle = PI * pow(randf(), 5) * signf(randf() - 0.5)

	var target_rotation_vector = Vector2.from_angle(target_angle + creature.rotation)

	var wander_distance = (randf() + 1) / 2 * wander_radius;

	return creature.global_position + target_rotation_vector * wander_distance
