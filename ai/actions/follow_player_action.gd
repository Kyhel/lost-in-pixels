class_name FollowPlayerAction
extends BTNode

enum FollowState { STOPPED, FOLLOWING, ORBITING }

const ORBIT_ZONE_MIN: float = 40.0
const ORBIT_ZONE_MAX: float = 100.0

const ORBIT_NEW_TARGET_DISTANCE: float = 10.0

var _follow_state: FollowState = FollowState.STOPPED

var orbit_target_position: Vector2 = Vector2.ZERO
var orbiting := false

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
					1.0))
		FollowState.ORBITING:
			if !orbiting or (player.global_position + orbit_target_position).distance_to(creature.global_position) < ORBIT_NEW_TARGET_DISTANCE:
				orbit_target_position = _choose_orbit_target()
				orbiting = true
			creature.movement.request_movement(
				MovementRequest.new(
					player.global_position + orbit_target_position,
					0))
		_:
			return State.FAILURE
	return State.RUNNING

# Selects a random position around the player, within the orbit zone
func _choose_orbit_target() -> Vector2:

	var rng := RandomNumberGenerator.new()

	var angle = rng.randf_range(0.0, TAU)
	var distance = rng.randf_range(ORBIT_ZONE_MIN, ORBIT_ZONE_MAX)

	return Vector2.from_angle(angle) * distance

func _update_follow_state(distance: float) -> void:
		
	if _follow_state == FollowState.STOPPED:
		_follow_state = FollowState.FOLLOWING

	# If the player is too far away, run back to the player
	if _follow_state == FollowState.ORBITING and distance > ORBIT_ZONE_MAX:
		_follow_state = FollowState.FOLLOWING
		return

	# If the player is close enough, orbit around the player
	if _follow_state == FollowState.FOLLOWING and distance < ORBIT_ZONE_MIN:
		_follow_state = FollowState.ORBITING
		return

func reset() -> void:
	super.reset()
	_follow_state = FollowState.STOPPED
	orbit_target_position = Vector2.ZERO
