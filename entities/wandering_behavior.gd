extends Node

## Makes the creature wander: move for a duration, stop, then move in a new random direction.
## Uses any random angle (not just cardinal directions) and rotates the creature to face movement.

@export var wander_speed: float = 40.0
@export var rotation_speed: float = TAU  ## Radians per second (TAU = 1 full turn per second)
@export var move_duration_min: float = 0.5
@export var move_duration_max: float = 1.5
@export var stop_duration_min: float = 0.5
@export var stop_duration_max: float = 1.5

const ROTATION_DONE_THRESHOLD: float = 0.01  ## Radians; consider rotation complete below this

var _state: int = 0  # 0 = moving, 1 = stopped
var _move_direction: Vector2
var _move_timer: float
var _stop_timer: float


func tick(creature: Creature, delta: float) -> void:
	if _state == 0:
		if _move_direction == Vector2.ZERO:
			_start_moving()
		var target_angle := _move_direction.angle()
		var angle_diff := angle_difference(creature.rotation, target_angle)
		var max_turn := rotation_speed * delta
		creature.rotation += sign(angle_diff) * min(abs(angle_diff), max_turn)
		var rotation_done: bool = abs(angle_difference(creature.rotation, target_angle)) <= ROTATION_DONE_THRESHOLD
		if rotation_done:
			creature.velocity = _move_direction * wander_speed
			_move_timer -= delta
			if _move_timer <= 0.0:
				creature.velocity = Vector2.ZERO
				_state = 1
				_stop_timer = randf_range(stop_duration_min, stop_duration_max)
		else:
			creature.velocity = Vector2.ZERO
	else:
		creature.velocity = Vector2.ZERO
		_stop_timer -= delta
		if _stop_timer <= 0.0:
			_start_moving()
			_state = 0


func _start_moving() -> void:
	_move_direction = Vector2.from_angle(randf() * TAU).normalized()
	_move_timer = randf_range(move_duration_min, move_duration_max)
