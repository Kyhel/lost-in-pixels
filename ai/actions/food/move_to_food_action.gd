class_name MoveToFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD) as Node2D

	if food == null:
		return State.FAILURE

	creature.movement.request_movement(MovementRequest.new(food.global_position, MovementRequest.MovementType.WALK))

	if PushPriorityHelper.is_within_interaction_range(creature, food):
		return State.SUCCESS

	return State.RUNNING
