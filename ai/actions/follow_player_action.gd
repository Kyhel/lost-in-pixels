class_name FollowPlayerAction
extends BTNode

enum FollowState { STOPPED, WALKING, RUNNING }

const ZONE1_MAX: float = 50.0   # inner: don't move (0 - 30)
const ZONE2_MAX: float = 100.0  # middle: walk (30 - 100), outer: run (> 100)
const HYSTERESIS: float = 10.0  # half-band each side of boundary

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

	return State.RUNNING

func _update_follow_state(distance: float) -> void:
	var leave_stop_threshold := ZONE1_MAX + HYSTERESIS / 2.0   # 35: stop -> walk
	var enter_stop_threshold := ZONE1_MAX - HYSTERESIS / 2.0   # 25: walk -> stop
	var leave_walk_threshold := ZONE2_MAX + HYSTERESIS / 2.0   # 105: walk -> run
	var enter_walk_from_run_threshold := ZONE2_MAX - HYSTERESIS / 2.0  # 95: run -> walk

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
