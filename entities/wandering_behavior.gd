extends Node

## Makes the creature wander: move a distance, stop, then move in a new random direction.
## Uses any random angle (not just cardinal directions) and rotates the creature to face movement.

@export var wander_speed: float = 40.0
@export var move_distance_min: float = 32.0
@export var move_distance_max: float = 96.0
@export var stop_duration_min: float = 0.5
@export var stop_duration_max: float = 1.5

var _state: int = 0  # 0 = moving, 1 = stopped
var _move_start_pos: Vector2
var _move_direction: Vector2
var _move_distance: float
var _stop_timer: float


func tick(creature: Creature, delta: float) -> void:
	if _state == 0:
		if _move_direction == Vector2.ZERO:
			_start_moving(creature.global_position)
		creature.velocity = _move_direction * wander_speed
		creature.rotation = _move_direction.angle()
		if creature.global_position.distance_to(_move_start_pos) >= _move_distance:
			creature.velocity = Vector2.ZERO
			_state = 1
			_stop_timer = randf_range(stop_duration_min, stop_duration_max)
	else:
		creature.velocity = Vector2.ZERO
		_stop_timer -= delta
		if _stop_timer <= 0.0:
			_start_moving(creature.global_position)
			_state = 0


func _start_moving(from_position: Vector2) -> void:
	_move_start_pos = from_position
	_move_direction = Vector2.from_angle(randf() * TAU).normalized()
	_move_distance = randf_range(move_distance_min, move_distance_max)
