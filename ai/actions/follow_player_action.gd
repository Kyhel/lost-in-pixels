class_name FollowPlayerAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	var player = creature.get_tree().get_first_node_in_group("player")
	if player == null:
		return State.FAILURE
	creature.movement.request_movement(MovementRequest.new(player.global_position, MovementRequest.MovementType.WALK))
	return State.RUNNING
