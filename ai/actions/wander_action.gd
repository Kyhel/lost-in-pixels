class_name WanderAction
extends BTNode

@export var wander_radius: float = 100.0

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		var target_angle = PI * pow(randf(), 5) * signf(randf() - 0.5)

		target_position = creature.global_position + Vector2.from_angle(target_angle + creature.rotation) * randf_range(0, wander_radius)
		
		creature.movement.move_to(target_position)

	if creature.global_position.distance_to(target_position) < 10:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING
