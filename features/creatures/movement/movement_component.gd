class_name MovementComponent
extends Node

var current_request: MovementRequest = null

var _strategy: MovementStrategy
var _cached_strategy_template_id: int = 0  ## 0 = none; Object.get_instance_id() of template MovementStrategy

func request_movement(request: MovementRequest) -> void:
	current_request = request

func stop() -> void:
	current_request = null
	_cached_strategy_template_id = 0
	if _strategy != null:
		_strategy.reset()

func update_movement(creature: Creature, delta: float) -> void:

	if current_request == null:
		creature.velocity = Vector2.ZERO
		return

	if creature.creature_data == null:
		return

	var profiles: Array[MovementProfile] = creature.creature_data.movement_profiles
	if profiles.is_empty():
		return

	var profile := _pick_profile(profiles, current_request)
	if profile == null:
		return

	var distance_to_target := _compute_distance_to_target(creature, current_request)
	var template := resolve_movement_strategy(current_request, profile, distance_to_target)
	if template == null:
		return

	if _cached_strategy_template_id != template.get_instance_id():
		_strategy = template.duplicate()
		_cached_strategy_template_id = template.get_instance_id()
		if _strategy != null:
			_strategy.reset()

	if _strategy == null:
		return

	_strategy.move(creature, current_request, delta)


func _pick_profile(profiles: Array[MovementProfile], request: MovementRequest) -> MovementProfile:
	for p in profiles:
		if p != null and p.context == request.context:
			return p
	return profiles[0]


func _compute_distance_to_target(creature: Creature, request: MovementRequest) -> float:
	var approach: Node2D = request.approach_target
	if approach != null and is_instance_valid(approach):
		return creature.global_position.distance_to(approach.global_position)
	return creature.global_position.distance_to(request.target_position)


func resolve_movement_strategy(
	request: MovementRequest,
	profile: MovementProfile,
	distance_to_target: float = 0.0,
) -> MovementStrategy:

	var best_score := -INF
	var best_strategy: MovementStrategy = null

	if profile == null:
		return null

	for entry in profile.entries:
		if entry == null or entry.strategy == null:
			continue

		var score := 0.0
		score += request.urgency * entry.urgency_weight
		score += request.energy_budget * entry.energy_weight
		score += request.precision * entry.precision_weight
		score += distance_to_target * entry.distance_weight

		if score > best_score:
			best_score = score
			best_strategy = entry.strategy

	if best_strategy == null and not profile.entries.is_empty():
		var first: MovementProfileEntry = profile.entries[0]
		if first != null:
			return first.strategy

	return best_strategy
