class_name MovementStrategy
extends Resource

@export var movement_type: CreatureData.MovementType = CreatureData.MovementType.DEFAULT

func move(_creature: Creature, _target_position: Vector2, _delta: float) -> void:
	pass

func reset() -> void:
	pass


## Shared logic for directed movement: rotate toward target, then set velocity to direction × speed.
## Used by WalkStrategy, RunStrategy, and SprintStrategy.
func _move_toward_with_speed(creature: Creature, target_position: Vector2, delta: float, speed: float) -> void:
	if creature.creature_data == null:
		return
	var dir = (target_position - creature.global_position).normalized()
	var target_angle := dir.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs: float = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta
	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)
	creature.velocity = dir * speed
