class_name MoveToPreyAction
extends BTNode

@export var target_blackboard_key: String = Blackboard.KEY_TARGET_FOOD

func tick(creature: Creature, _delta: float) -> State:
	var target = creature.blackboard.get_value(target_blackboard_key) as Node2D
	if target == null:
		return State.FAILURE
	if not target is Creature:
		return State.FAILURE

	creature.movement.request_movement(MovementRequest.to_eat_live_prey(target as Creature))
	if Node2DUtils.is_within_interaction_range(creature, target):
		return State.SUCCESS
	return State.RUNNING
