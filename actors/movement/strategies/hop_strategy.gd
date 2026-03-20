class_name HopStrategy
extends MovementStrategy

var rest_duration: float = 0
var hop_duration: float = 0
var hop_ratio: float = 0

@export var rest_ratio: float = 0.5
@export var hop_base_duration: float = 0.7

var hop_timer: float = 0.0

func _init() -> void:
	hop_ratio = 1 - rest_ratio
	hop_duration = hop_base_duration * hop_ratio
	rest_duration = hop_base_duration * rest_ratio

func move(creature: Creature, request: MovementRequest, delta: float) -> void:

	hop_timer -= delta

	if hop_timer <= 0.0:
		hop_timer = hop_base_duration

	var k: Dictionary = _resolve_request_kinematics(creature, request)
	if not k["allow_translate"]:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return

	if hop_timer < rest_duration:
		creature.velocity = Vector2.ZERO
		return

	var move_goal: Vector2 = k["move_goal"]
	var direction: Vector2 = (move_goal - creature.global_position)
	if direction.length_squared() < 0.0001:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return
	direction = direction.normalized()
	var target_angle := direction.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta

	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	if angle_diff_abs >= NO_MOVEMENT_DIRECTION_THRESHOLD:
		creature.velocity = Vector2.ZERO
		return

	var max_speed = creature.creature_data.base_speed * creature.creature_data.running_multiplier
	var base_speed = creature.creature_data.base_speed

	var relative_speed = lerp(base_speed, max_speed, request.speed_desire)

	var speed = relative_speed * creature.creature_data.hop_multiplier / hop_ratio

	var rotation_ratio = (NO_MOVEMENT_DIRECTION_THRESHOLD - angle_diff_abs) / NO_MOVEMENT_DIRECTION_THRESHOLD

	creature.velocity = Vector2.from_angle(creature.virtual_rotation).normalized() * speed * rotation_ratio

func reset() -> void:
	hop_timer = 0.0
