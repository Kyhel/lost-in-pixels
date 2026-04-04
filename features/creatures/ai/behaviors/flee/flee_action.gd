class_name FleeAction
extends BTNode

const FLEE_PICK_ATTEMPTS := 5
const AWAY_EPS := 0.0001

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		var data := creature.creature_data
		var flee_radius := _get_flee_radius(creature)
		if data == null or flee_radius <= 0.0:
			creature.movement.stop()
			return State.RUNNING

		var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
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
			picked = creature.global_position + dir * (2.0 * flee_radius)
			if CreatureUtils.is_valid_wander_destination(creature, picked):
				found = true
				break

		if not found:
			creature.movement.stop()
			return State.RUNNING

		target_position = picked
		var flee_request := MovementRequest.to_world_position(target_position, 1.0)
		flee_request.urgency = 1.0
		creature.movement.request_movement(flee_request)

	if creature.global_position.distance_to(target_position) < 15:

		creature.movement.stop()
		target_position = null
		return State.SUCCESS

	return State.RUNNING

func reset() -> void:
	super.reset()
	target_position = null


static func _get_flee_radius(creature: Creature) -> float:
	if creature.needs_component != null:
		var inst: NeedInstance = creature.needs_component.get_instance(NeedIds.FEAR)
		if inst != null and inst.need is FearNeed:
			return (inst.need as FearNeed).fear_player_distance
	return 0.0
