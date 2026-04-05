class_name FreeRoamAction
extends BTNode

const PICK_ATTEMPTS := 8

@export var max_radius: float = 320.0
@export var wander_radius: float = 140.0
@export var arrival_distance: float = 15.0

var _recall_mode: bool = false
var _has_target: bool = false
var _target_position: Vector2


func tick(creature: Creature, _delta: float) -> State:
	var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	if player == null:
		return State.FAILURE

	var dist_to_player := creature.global_position.distance_to(player.global_position)
	var inner_r := max_radius * 0.5

	if dist_to_player > max_radius:
		_recall_mode = true
		_has_target = false

	if _recall_mode:
		var to_creature := creature.global_position - player.global_position
		if to_creature.length_squared() < 1e-6:
			to_creature = Vector2.RIGHT
		var recall_target := player.global_position + to_creature.normalized() * inner_r
		creature.movement.request_movement(MovementRequest.to_world_position(recall_target, 1.0))
		if creature.global_position.distance_to(recall_target) < arrival_distance or dist_to_player <= max_radius:
			_recall_mode = false
			_has_target = false
		return State.RUNNING

	if not _has_target:
		var picked := _pick_free_roam_point(creature, player, inner_r)
		if picked == Vector2.ZERO:
			creature.movement.stop()
			return State.RUNNING
		_target_position = picked
		_has_target = true
		creature.movement.request_movement(MovementRequest.to_world_position(_target_position, 0.85))

	if creature.global_position.distance_to(_target_position) < arrival_distance:
		creature.movement.stop()
		_has_target = false
		return State.SUCCESS

	return State.RUNNING


func _pick_free_roam_point(creature: Creature, player: Node2D, inner_r: float) -> Vector2:
	var best: Vector2 = Vector2.ZERO
	var best_score := -INF
	for _i in PICK_ATTEMPTS:
		var cand_global := _sample_wander_point(creature)
		if not CreatureUtils.is_valid_wander_destination(creature, cand_global):
			continue
		var pd := cand_global.distance_to(player.global_position)
		var score: float
		if pd >= inner_r and pd <= max_radius:
			score = 1.0
		elif pd < inner_r:
			score = pd / maxf(inner_r, 0.01) * 0.5
		else:
			score = maxf(0.0, 1.0 - (pd - max_radius) / maxf(max_radius, 0.01))
		if score > best_score:
			best_score = score
			best = cand_global
	if best_score <= -INF:
		return Vector2.ZERO
	return best


func _sample_wander_point(creature: Creature) -> Vector2:
	var target_angle := PI * pow(randf(), 5) * signf(randf() - 0.5)
	var target_rotation_vector := Vector2.from_angle(target_angle + creature.virtual_rotation)
	var dist := (randf() + 1.0) * 0.5 * wander_radius
	return creature.global_position + target_rotation_vector * dist


func reset() -> void:
	super.reset()
	_recall_mode = false
	_has_target = false
	_target_position = Vector2.ZERO
