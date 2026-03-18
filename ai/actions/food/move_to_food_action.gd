class_name MoveToFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD) as Node2D

	if food == null:
		return State.FAILURE

	var speed_desire := 0.0

	if food is Creature:
		speed_desire = 1.0

	creature.movement.request_movement(MovementRequest.new(food.global_position, speed_desire))

	if PushPriorityHelper.is_within_interaction_range(creature, food):
		return State.SUCCESS

	return State.RUNNING
