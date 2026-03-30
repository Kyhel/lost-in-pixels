extends Node2D
class_name CreatureDebug

## Movement debug overlay: stores steering vectors and draws Line2D helpers on the parent [Creature].

var seek: Vector2 = Vector2.ZERO
var separation: Vector2 = Vector2.ZERO
var avoidance: Vector2 = Vector2.ZERO
var steering: Vector2 = Vector2.ZERO
var final_velocity: Vector2 = Vector2.ZERO

@onready var _speed_line: Line2D = $SpeedLine
@onready var _separation_line: Line2D = $SeparationLine
@onready var _avoidance_line: Line2D = $AvoidanceLine


func reset_vectors() -> void:
	seek = Vector2.ZERO
	separation = Vector2.ZERO
	avoidance = Vector2.ZERO
	steering = Vector2.ZERO
	final_velocity = Vector2.ZERO


func set_movement_debug(
	p_seek: Vector2,
	p_separation: Vector2,
	p_avoidance: Vector2,
	p_steering: Vector2,
	p_final_velocity: Vector2
) -> void:
	seek = p_seek
	separation = p_separation
	avoidance = p_avoidance
	steering = p_steering
	final_velocity = p_final_velocity


func _process(_delta: float) -> void:
	if not visible:
		return
	var body := get_parent() as CharacterBody2D
	if body == null:
		return
	_update_line_points(_speed_line, Vector2.ZERO, body.velocity)
	_update_line_points(_separation_line, Vector2.ZERO, separation * 100.0)
	_update_line_points(_avoidance_line, Vector2.ZERO, avoidance)


func _update_line_points(line: Line2D, start: Vector2, end: Vector2) -> void:
	if line == null:
		return
	var pts := PackedVector2Array()
	pts.push_back(start)
	pts.push_back(end)
	line.points = pts
