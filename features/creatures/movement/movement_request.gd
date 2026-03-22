class_name MovementRequest
extends RefCounted

enum MovementContext {
	WANDER,
	EAT,
	FOLLOW_PLAYER,
	FLY,
}

## How close is "done" when [member approach_target] is set: INTERACTION stops translation at
## [constant Constants.INTERACTION_APPROACH_STOP_MARGIN] (tighter) while actual interaction checks use
## [constant Constants.DEFAULT_INTERACTION_MARGIN] (wider so interact can succeed before the hold);
## COMBAT uses combined radii + [constant Constants.DEFAULT_COMBAT_APPROACH_STANDOFF]; CUSTOM uses distance to move goal + [member completion_distance_threshold].
enum ApproachSpacing {
	CUSTOM,
	INTERACTION,
	COMBAT,
}

var target_position: Vector2
var speed_desire: float = 0.5 # Should be between 0.0 and 1.0
var context: MovementContext
var urgency: float = 0.0
var energy_budget: float = 0.0
var precision: float = 0.0

## When true, the creature still rotates toward the face point while translation is suppressed.
var face_target: bool = false

## Translation stops when distance from the creature to the resolved move goal is at or below this (world units).
var completion_distance_threshold: float = 4.0

## If set, move goal is computed from this node each physics frame (intercept-predicted if CharacterBody2D).
var approach_target: Node2D = null

var approach_spacing: ApproachSpacing = ApproachSpacing.CUSTOM

## Added to predicted [approach_target] position (e.g. orbit slot around the target).
var target_offset: Vector2 = Vector2.ZERO

func _init(_target_position: Vector2, _speed_desire: float = 0.5) -> void:
	target_position = _target_position
	speed_desire = _speed_desire


## Plain movement to a fixed world point (wander, static food, fly waypoint). No tracked target.
static func to_world_position(world_position: Vector2, desire: float = 0.5) -> MovementRequest:
	return MovementRequest.new(world_position, desire)


## Chase live prey: seek predicted center until interaction range; face target while holding.
static func to_eat_live_prey(prey: Creature, desire: float = 1.0) -> MovementRequest:
	var r := MovementRequest.new(prey.global_position, desire)
	r.context = MovementContext.EAT
	r.approach_target = prey
	r.approach_spacing = ApproachSpacing.INTERACTION
	r.face_target = true
	return r


## Chase / hold at combat distance (combined radii + combat spacing).
static func to_combat_engage(target: Node2D, desire: float = 1.0) -> MovementRequest:
	var r := MovementRequest.new(target.global_position, desire)
	r.approach_target = target
	r.approach_spacing = ApproachSpacing.COMBAT
	r.face_target = true
	return r


## Follow a moving node to its predicted position.
static func to_follow_moving(target: Node2D, desire: float = 1.0) -> MovementRequest:
	var r := MovementRequest.new(target.global_position, desire)
	r.context = MovementContext.FOLLOW_PLAYER
	r.approach_target = target
	r.approach_spacing = ApproachSpacing.CUSTOM
	return r


## Orbit slot: [param world_offset_from_target] is kept relative to [param target] each physics tick.
static func to_orbit_around(
	target: Node2D,
	world_offset_from_target: Vector2,
	desire: float = 0.0,
) -> MovementRequest:
	var r := MovementRequest.new(target.global_position + world_offset_from_target, desire)
	r.context = MovementContext.FOLLOW_PLAYER
	r.approach_target = target
	r.target_offset = world_offset_from_target
	r.approach_spacing = ApproachSpacing.CUSTOM
	return r
