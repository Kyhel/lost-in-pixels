class_name HopStrategy
extends MovementStrategy

var rest_duration: float = 0
var hop_duration: float = 0
var hop_ratio: float = 0

@export var rest_ratio: float = 0.5
@export var hop_base_duration: float = 0.7

var hop_timer: float = 0.0

func _init() -> void:
	hop_ratio = 1 - rest_ratio
	hop_duration = hop_base_duration * hop_ratio
	rest_duration = hop_base_duration * rest_ratio

func move(creature: Creature, target_position: Vector2, delta: float, speed_desire: float) -> void:

	hop_timer -= delta

	if hop_timer <= 0.0:
		hop_timer = hop_base_duration

	if hop_timer < rest_duration:
		creature.velocity = Vector2.ZERO
		return

	var direction = (target_position - creature.global_position).normalized()
	var target_angle := direction.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta

	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	if angle_diff_abs >= NO_MOVEMENT_DIRECTION_THRESHOLD:
		creature.velocity = Vector2.ZERO
		return

	var max_speed = creature.creature_data.base_speed * creature.creature_data.running_multiplier
	var base_speed = creature.creature_data.base_speed

	var relative_speed = lerp(base_speed, max_speed, speed_desire)

	var speed = relative_speed * creature.creature_data.hop_multiplier / hop_ratio

	var rotation_ratio = (NO_MOVEMENT_DIRECTION_THRESHOLD - angle_diff_abs) / NO_MOVEMENT_DIRECTION_THRESHOLD

	creature.velocity = Vector2.from_angle(creature.virtual_rotation).normalized() * speed * rotation_ratio

func reset() -> void:
	hop_timer = 0.0
