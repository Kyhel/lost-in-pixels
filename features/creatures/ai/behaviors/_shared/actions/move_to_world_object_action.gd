class_name MoveToWorldObjectAction
extends BTNode


func tick(creature: Creature, _delta: float) -> State:
	var target = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)
	if not is_instance_valid(target) or not target is WorldObject:
		return State.FAILURE

	creature.movement.request_movement(
		MovementRequest.to_interact_target(target, 0.0, MovementRequest.MovementContext.EAT))
	
	if Node2DUtils.is_within_interaction_range(creature, target):
		return State.SUCCESS
	
	return State.RUNNING
