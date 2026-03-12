class_name MovementComponent
extends Node

const ROTATION_DONE_THRESHOLD: float = 0.01  ## Radians; consider rotation complete below this

@export var walking_speed := 40.0
@export var rotating_speed := TAU

var target_position : Vector2
var has_target := false

func move_to(pos: Vector2) -> void:
	target_position = pos
	has_target = true

func stop() -> void:
	has_target = false

func update_movement(creature: Creature, delta: float) -> void:

	if not has_target:
		creature.velocity = Vector2.ZERO
		return

	var dir = (target_position - creature.global_position).normalized()
	var target_angle := dir.angle()
	var angle_diff := angle_difference(creature.rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := rotating_speed * delta
	creature.rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	if angle_diff_abs <= ROTATION_DONE_THRESHOLD:
		creature.velocity = dir * walking_speed
		return

	var rotation_ratio = max(0, (PI - angle_diff_abs) / PI - 0.5)

	creature.velocity = Vector2.from_angle(creature.rotation) * walking_speed * rotation_ratio
