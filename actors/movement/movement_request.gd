class_name MovementRequest
extends RefCounted

enum MovementType {
	SNEAK,
	WALK,
	RUN,
	SPRINT
}

var target_position: Vector2
var movement_type: MovementType

func _init(pos: Vector2 = Vector2.ZERO, type: MovementType = MovementType.WALK) -> void:
	target_position = pos
	movement_type = type
