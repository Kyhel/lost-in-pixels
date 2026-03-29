class_name WanderAction
extends BTNode

const WANDER_PICK_ATTEMPTS := 5

@export var wander_radius: float = 200.0

var target_position

func tick(creature: Creature, _delta: float) -> State:

	if target_position == null:

		var picked: Vector2 = Vector2.ZERO
		var found := false

		for _i in WANDER_PICK_ATTEMPTS:
			picked = pick_wander_point(creature)
			if not CreatureUtils.is_valid_wander_destination(creature, picked):
				continue
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

func pick_wander_point(creature: Creature) -> Vector2:

	var target_angle = PI * pow(randf(), 5) * signf(randf() - 0.5)

	var target_rotation_vector = Vector2.from_angle(target_angle + creature.virtual_rotation)

	var wander_distance = (randf() + 1) / 2 * wander_radius;

	return creature.global_position + target_rotation_vector * wander_distance

func reset() -> void:
	super.reset()
	target_position = null
