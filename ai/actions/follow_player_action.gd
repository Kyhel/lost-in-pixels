class_name FollowPlayerAction
extends BTNode

enum FollowState { STOPPED, WALKING, RUNNING, SPRINTING }

const ZONE1_MAX: float = 50.0    # inner: don't move
const ZONE2_MAX: float = 100.0   # walk
const ZONE3_MAX: float = 200.0   # run; beyond: sprint
const HYSTERESIS: float = 5   # each side of boundary

var _follow_state: FollowState = FollowState.WALKING

func tick(creature: Creature, _delta: float) -> State:
	var player = creature.get_tree().get_first_node_in_group("player")
	if player == null:
		return State.FAILURE

	var distance = creature.global_position.distance_to(player.global_position)
	_update_follow_state(distance)

	match _follow_state:
		FollowState.STOPPED:
			creature.movement.stop()
		FollowState.WALKING:
			creature.movement.request_movement(MovementRequest.new(player.global_position, MovementRequest.MovementType.WALK))
		FollowState.RUNNING:
			creature.movement.request_movement(MovementRequest.new(player.global_position, MovementRequest.MovementType.RUN))
		FollowState.SPRINTING:
			creature.movement.request_movement(MovementRequest.new(player.global_position, MovementRequest.MovementType.SPRINT))

	return State.RUNNING

func _update_follow_state(distance: float) -> void:
	var leave_stop_threshold := ZONE1_MAX + HYSTERESIS
	var enter_stop_threshold := ZONE1_MAX - HYSTERESIS
	var leave_walk_threshold := ZONE2_MAX + HYSTERESIS
	var enter_walk_from_run_threshold := ZONE2_MAX - HYSTERESIS
	var leave_run_threshold := ZONE3_MAX + HYSTERESIS   # run -> sprint
	var enter_run_from_sprint_threshold := ZONE3_MAX - HYSTERESIS  # sprint -> run

	match _follow_state:
		FollowState.STOPPED:
			if distance > leave_stop_threshold:
				_follow_state = FollowState.WALKING
		FollowState.WALKING:
			if distance < enter_stop_threshold:
				_follow_state = FollowState.STOPPED
			elif distance > leave_walk_threshold:
				_follow_state = FollowState.RUNNING
		FollowState.RUNNING:
			if distance < enter_walk_from_run_threshold:
				_follow_state = FollowState.WALKING
			elif distance > leave_run_threshold:
				_follow_state = FollowState.SPRINTING
		FollowState.SPRINTING:
			if distance < enter_run_from_sprint_threshold:
				_follow_state = FollowState.RUNNING
