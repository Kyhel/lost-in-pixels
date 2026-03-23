class_name ChasePlayerAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER) != true:
		creature.movement.stop()
		return State.FAILURE

	var player := creature.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		creature.movement.stop()
		return State.FAILURE

	if Node2DUtils.is_within_interaction_range(
		creature,
		player,
		creature.creature_data.attack_range
	):
		return State.SUCCESS

	creature.movement.request_movement(MovementRequest.to_combat_engage(player, 1.0))

	return State.RUNNING
