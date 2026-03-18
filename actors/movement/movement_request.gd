class_name MovementRequest
extends RefCounted

enum MovementContext {
	WANDER,
	EAT,
	FOLLOW_PLAYER,
	FLY,
}

var target_position: Vector2
var speed_desire: float = 0.5 # Should be between 0.0 and 1.0
var context: MovementContext
var urgency: float = 0.0
var energy_budget: float = 0.0
var precision: float = 0.0
var distance_to_target: float = 0.0

func _init(
	_target_position: Vector2,
	_speed_desire: float) -> void:
	target_position = _target_position
	speed_desire = _speed_desire
	
