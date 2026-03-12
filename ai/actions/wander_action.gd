class_name WanderAction
extends BTNode

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		target_position = creature.global_position + Vector2(
			randf_range(-200,200),
			randf_range(-200,200)
		)

		creature.movement.move_to(target_position)

	if creature.global_position.distance_to(target_position) < 10:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING
