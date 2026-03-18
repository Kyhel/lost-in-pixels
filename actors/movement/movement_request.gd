class_name MovementRequest
extends RefCounted

enum MovementContext {
	WANDER,
	EAT,
	FOLLOW_PLAYER,
	FLY,
}

var target_position: Vector2
var context: MovementContext
var urgency: float = 0.0
var energy_budget: float = 0.0
var precision: float = 0.0
var distance_to_target: float = 0.0

func _init(
	pos: Vector2,
	type: MovementContext,
	_urgency: float = 0.0,
	_energy_budget: float = 0.0,
	_precision: float = 0.0,
	distance_to_target: float = 0.0) -> void:
	urgency = _urgency
	energy_budget = _energy_budget
	precision = _precision
	self.distance_to_target = distance_to_target
	target_position = pos
	context = type
	
