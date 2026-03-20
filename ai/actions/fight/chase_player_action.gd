class_name ChasePlayerAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var player := creature.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return State.FAILURE

	creature.movement.request_movement(MovementRequest.to_combat_engage(player, 1.0))

	return State.RUNNING
