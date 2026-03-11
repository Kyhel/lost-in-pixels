extends Node

## Simple bird-like flight: fly straight for a while, then turn slowly toward a new direction.
## Keeps the creature in motion and aligns the sprite to movement.

@export var fly_speed: float = 50.0
@export var straight_duration_min: float = 1.0
@export var straight_duration_max: float = 3.0
@export var turn_duration_min: float = 0.3
@export var turn_duration_max: float = 0.8
@export var turn_speed: float = 2.5  # radians per second while turning

enum State { FLYING_STRAIGHT, TURNING }

var _state: int = State.FLYING_STRAIGHT
var _current_angle: float = 0.0
var _target_angle: float = 0.0
var _timer: float = 0.0


func tick(creature: Creature, delta: float) -> void:
	_current_angle = fposmod(_current_angle, TAU)
	if _state == State.FLYING_STRAIGHT:
		var direction = Vector2.from_angle(_current_angle)
		creature.velocity = direction * fly_speed
		creature.rotation = _current_angle

		_timer -= delta
		if _timer <= 0.0:
			_target_angle = randf() * TAU
			_timer = randf_range(turn_duration_min, turn_duration_max)
			_state = State.TURNING

	else:  # TURNING
		_current_angle = move_toward_angle(_current_angle, _target_angle, turn_speed * delta)
		var direction = Vector2.from_angle(_current_angle)
		creature.velocity = direction * fly_speed
		creature.rotation = _current_angle

		_timer -= delta
		if _timer <= 0.0:
			# Keep current angle — don't snap to target, so no visible jump
			_timer = randf_range(straight_duration_min, straight_duration_max)
			_state = State.FLYING_STRAIGHT


func _ready() -> void:
	_current_angle = randf() * TAU
	_timer = randf_range(straight_duration_min, straight_duration_max)


static func move_toward_angle(from: float, to: float, delta: float) -> float:
	var diff = fposmod(to - from + PI, TAU) - PI
	if abs(diff) <= delta:
		return to
	return from + sign(diff) * delta