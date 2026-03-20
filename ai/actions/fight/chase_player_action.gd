class_name ChasePlayerAction
extends BTNode

const STANDOFF_DISTANCE: float = 5.0
const COMPLETION_DISTANCE: float = 4.0

func tick(creature: Creature, _delta: float) -> State:

	var player := creature.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return State.FAILURE

	var chase_req := MovementRequest.new(player.global_position, 1.0)
	chase_req.face_target = true
	chase_req.completion_distance_threshold = COMPLETION_DISTANCE
	chase_req.approach_target = player
	chase_req.standoff_distance = STANDOFF_DISTANCE
	creature.movement.request_movement(chase_req)

	return State.RUNNING
