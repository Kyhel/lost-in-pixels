class_name FollowPlayerAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	var player = creature.get_tree().get_first_node_in_group("player")
	if player == null:
		return State.FAILURE
	creature.movement.move_to(player.global_position)
	return State.RUNNING
