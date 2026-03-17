class_name MovementRequest
extends RefCounted

var target_position: Vector2
var movement_type: CreatureData.MovementType

func _init(pos: Vector2 = Vector2.ZERO, type: CreatureData.MovementType = CreatureData.MovementType.WALK) -> void:
	target_position = pos
	movement_type = type
