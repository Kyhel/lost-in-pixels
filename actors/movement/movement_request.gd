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

## When true, the creature still rotates toward [face_point] while translation is suppressed
## (e.g. within [completion_distance_threshold] of [move_goal]).
var face_target: bool = false

## Translation stops when distance from the creature to the resolved [move_goal] is at or below this (world units).
var completion_distance_threshold: float = 4.0

## If set, [move_goal] is computed on the ring around this node using both hitbox radii and [standoff_distance].
## [target_position] is ignored for pathing while this is valid; it can still be set for debugging or future use.
var approach_target: Node2D = null

## Extra gap beyond touching hitboxes when [approach_target] is used (world units).
var standoff_distance: float = 0.0

func _init(_target_position: Vector2, _speed_desire: float = 0.5) -> void:
	target_position = _target_position
	speed_desire = _speed_desire
