class_name HopStrategy
extends MovementStrategy

@export var rest_duration: float = 0.5
@export var hop_duration: float = 0.2

var hop_timer: float = 0.0

const NO_MOVEMENT_DIRECTION_THRESHOLD: float = PI / 2

func move(creature: Creature, target_position: Vector2, delta: float) -> void:

	hop_timer -= delta

	if hop_timer < 0.0:
		hop_timer = rest_duration + hop_duration

	if hop_timer < rest_duration:
		creature.velocity = Vector2.ZERO
		return

	var direction = (target_position - creature.global_position).normalized()
	var target_angle := direction.angle()
	var angle_diff := angle_difference(creature.rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta

	creature.rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	if angle_diff_abs >= NO_MOVEMENT_DIRECTION_THRESHOLD:
		creature.velocity = Vector2.ZERO
		return

	var hop_time_ratio = (rest_duration + hop_duration) / hop_duration

	var speed = creature.creature_data.base_speed * creature.creature_data.hop_multiplier * hop_time_ratio

	var rotation_ratio = (NO_MOVEMENT_DIRECTION_THRESHOLD - angle_diff_abs) / NO_MOVEMENT_DIRECTION_THRESHOLD

	creature.velocity = Vector2.from_angle(creature.rotation).normalized() * speed * rotation_ratio

func reset() -> void:
	hop_timer = 0.0
