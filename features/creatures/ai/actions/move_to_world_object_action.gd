class_name MoveToWorldObjectAction
extends BTNode

@export var target_blackboard_key: String = Blackboard.KEY_TARGET_FOOD
@export var movement_context: MovementRequest.MovementContext = MovementRequest.MovementContext.EAT

func tick(creature: Creature, _delta: float) -> State:
	var target = creature.blackboard.get_value(target_blackboard_key) as Node2D
	if target == null:
		return State.FAILURE
	if not target is WorldObject:
		return State.FAILURE

	creature.movement.request_movement(MovementRequest.to_interact_target(target, 1.0, movement_context))
	if Node2DUtils.is_within_interaction_range(creature, target):
		return State.SUCCESS
	return State.RUNNING
