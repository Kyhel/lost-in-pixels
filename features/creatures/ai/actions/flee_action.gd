class_name FleeAction
extends BTNode

const FLEE_PICK_ATTEMPTS := 5
const AWAY_EPS := 0.0001

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		var data := creature.creature_data
		if data == null or data.fear_player_distance <= 0.0:
			creature.movement.stop()
			return State.RUNNING

		var player := creature.get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Node2D
		if player == null:
			creature.movement.stop()
			return State.RUNNING

		var base_away := creature.global_position - player.global_position
		if base_away.length_squared() < AWAY_EPS:
			base_away = Vector2.RIGHT.rotated(randf() * TAU)
		else:
			base_away = base_away.normalized()

		var picked: Vector2 = Vector2.ZERO
		var found := false

		for i in FLEE_PICK_ATTEMPTS:
			var dir := base_away
			if i > 0:
				dir = base_away.rotated(randf_range(-0.6, 0.6))
			picked = creature.global_position + dir * (2.0 * data.fear_player_distance)
			if CreatureUtils.is_valid_wander_destination(creature, picked):
				found = true
				break

		if not found:
			creature.movement.stop()
			return State.RUNNING

		target_position = picked
		creature.movement.request_movement(MovementRequest.to_world_position(target_position, 0.0))

	if creature.global_position.distance_to(target_position) < 15:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING

func reset() -> void:
	super.reset()
	target_position = null
