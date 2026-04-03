class_name MoveToPreyAction
extends BTNode


func tick(creature: Creature, _delta: float) -> State:
	
	var target = creature.blackboard.get_value(Blackboard.KEY_TARGET_CREATURE)
	if target == null or not is_instance_valid(target) or not target is Creature:
		return State.FAILURE
		
	var target_creature := target as Creature

	creature.movement.request_movement(MovementRequest.to_eat_live_prey(target_creature as Creature))
	
	if Node2DUtils.is_within_interaction_range(creature, target_creature):
		return State.SUCCESS
		
	return State.RUNNING
