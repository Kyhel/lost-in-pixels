class_name MoveToFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD) as Node2D

	if food == null:
		return State.FAILURE

	if food is Creature:
		creature.movement.request_movement(MovementRequest.to_eat_live_prey(food as Creature))
	else:
		creature.movement.request_movement(MovementRequest.to_interact_target(food, 0.0))

	if Node2DUtils.is_within_interaction_range(creature, food):
		return State.SUCCESS

	return State.RUNNING
