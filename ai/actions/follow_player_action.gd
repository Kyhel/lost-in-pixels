class_name FollowPlayerAction
extends BTNode

enum FollowState { STOPPED, FOLLOWING }

const ZONE1_MAX: float = 50.0    # inner: don't move
const HYSTERESIS: float = 5   # each side of boundary

var _follow_state: FollowState = FollowState.STOPPED

func tick(creature: Creature, _delta: float) -> State:
	var player = creature.get_tree().get_first_node_in_group("player")
	if player == null:
		return State.FAILURE

	var distance = creature.global_position.distance_to(player.global_position)
	_update_follow_state(distance)

	match _follow_state:
		FollowState.STOPPED:
			creature.movement.stop()
		FollowState.FOLLOWING:
			creature.movement.request_movement(
				MovementRequest.new(
					player.global_position,
					MovementRequest.MovementContext.FOLLOW_PLAYER,
					0.0,
					0.0,
					100,
					distance))

	return State.RUNNING

func _update_follow_state(distance: float) -> void:
	var leave_stop_threshold := ZONE1_MAX + HYSTERESIS
	var enter_stop_threshold := ZONE1_MAX - HYSTERESIS

	match _follow_state:
		FollowState.STOPPED:
			if distance > leave_stop_threshold:
				_follow_state = FollowState.FOLLOWING
		FollowState.FOLLOWING:
			if distance < enter_stop_threshold:
				_follow_state = FollowState.STOPPED
