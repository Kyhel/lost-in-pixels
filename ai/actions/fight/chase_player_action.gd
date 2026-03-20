class_name ChasePlayerAction
extends BTNode

const SAFE_DISTANCE: float = 5

func tick(creature: Creature, _delta: float) -> State:

	var player := creature.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return State.FAILURE

	var to_player: Vector2 = player.global_position - creature.global_position
	var distance: float = to_player.length()
	var contact_distance: float = creature.get_hitbox_radius() + player.get_hitbox_radius() + SAFE_DISTANCE

	if distance <= contact_distance:
		creature.movement.stop()
		return State.RUNNING

	var direction := to_player / maxf(distance, 0.001)
	var target_position: Vector2 = player.global_position - direction * contact_distance

	creature.movement.request_movement(
		MovementRequest.new(
			target_position,
			1.0))

	return State.RUNNING
