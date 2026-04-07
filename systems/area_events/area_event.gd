class_name AreaEvent
extends Resource

@export var id: StringName = &""
@export var radius: float = 100.0


func apply(_world_position: Vector2) -> void:
	push_warning("AreaEvent.apply not implemented for %s" % id)
