class_name MoveToFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD) as WorldItem

	if food == null:
		return State.FAILURE

	creature.movement.move_to(food.global_position)

	if creature.global_position.distance_to(food.global_position) < 10:
		return State.SUCCESS

	return State.RUNNING
