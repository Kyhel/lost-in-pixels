class_name ReturnToPlayerWithHeldObjectAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	if not creature.is_holding_world_object():
		return State.FAILURE

	var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	if player == null:
		return State.FAILURE

	creature.movement.request_movement(MovementRequest.to_follow_moving(player, 1.0))
	if Node2DUtils.is_within_interaction_range(creature, player):
		return State.SUCCESS
	return State.RUNNING
