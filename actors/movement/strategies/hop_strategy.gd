class_name HopStrategy
extends MovementStrategy

@export var rest_duration: float = 0.8
@export var hop_duration: float = 0.2

var hop_timer: float = 0.0

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

	# var hop_time_ratio = 1
	var hop_time_ratio = hop_duration / (rest_duration + hop_duration)

	var speed = creature.creature_data.base_speed * creature.creature_data.hop_multiplier / hop_time_ratio

	creature.velocity = direction * speed

func reset() -> void:
	hop_timer = 0.0
