class_name MovementComponent
extends Node

var current_request: MovementRequest = null

var _strategy: MovementStrategy
var _cached_strategy_for_type: int = -1  ## MovementRequest.MovementType we cached for; -1 = none
var _strategy_cache: Dictionary = {}  ## MovementRequest.MovementType -> MovementStrategy (reuse instances per request type)

var _walk_strategy_priority: Array[CreatureData.MovementType] = [
	CreatureData.MovementType.HOP,
	CreatureData.MovementType.DEFAULT,
	CreatureData.MovementType.WALK
]

func request_movement(request: MovementRequest) -> void:
	current_request = request

func stop() -> void:
	current_request = null
	_cached_strategy_for_type = -1
	if _strategy != null:
		_strategy.reset()
	# Keep _strategy_cache so we reuse instances when movement resumes

func update_movement(creature: Creature, delta: float) -> void:

	if current_request == null:
		creature.velocity = Vector2.ZERO
		return

	if creature.creature_data == null:
		return

	# Resolve strategy for this request type (reuse cached instance if we have one)
	if _cached_strategy_for_type != current_request.movement_type:
		var request_type: int = current_request.movement_type
		if _strategy_cache.has(request_type):
			_strategy = _strategy_cache[request_type]
		else:
			_strategy = _resolve_strategy(creature, request_type)
			if _strategy != null:
				_strategy_cache[request_type] = _strategy
		_cached_strategy_for_type = request_type
		if _strategy != null:
			_strategy.reset()

	if _strategy == null:
		return

	_strategy.move(creature, current_request.target_position, delta)

## Returns a duplicated strategy instance for the given request type and creature's available movement_types.
## Falls back to DefaultStrategy when no strategy is found (e.g. empty movement_types or no match).
func _resolve_strategy(creature: Creature, request_movement_type: int) -> MovementStrategy:
	var types: Array = creature.creature_data.movement_types
	if types.is_empty():
		return _get_default_strategy_or_null()

	match request_movement_type:
		MovementRequest.MovementType.WALK:
			for priority_type in _walk_strategy_priority:
				if priority_type in types:
					var strat = MovementStrategyDatabase.get_strategy(priority_type)
					return strat.duplicate() if strat != null else _get_default_strategy_or_null()
			return _get_default_strategy_or_null()
		MovementRequest.MovementType.RUN:
			if CreatureData.MovementType.RUN in types:
				var run_strat = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.RUN)
				return run_strat.duplicate() if run_strat != null else _get_default_strategy_or_null()
			# Fall through to first available
		MovementRequest.MovementType.SPRINT:
			if CreatureData.MovementType.SPRINT in types:
				var sprint_strat = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.SPRINT)
				if sprint_strat != null:
					return sprint_strat.duplicate()
			if CreatureData.MovementType.RUN in types:
				var run_strat = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.RUN)
				return run_strat.duplicate() if run_strat != null else _get_default_strategy_or_null()
			# Fall through to first available
		_:
			pass

	# No match or SNEAK/other: use first available strategy for this creature
	var first_type = types[0]
	var fallback_strat = MovementStrategyDatabase.get_strategy(first_type)
	return fallback_strat.duplicate() if fallback_strat != null else _get_default_strategy_or_null()

func _get_default_strategy_or_null() -> MovementStrategy:
	var s = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.DEFAULT)
	return s.duplicate() if s != null else null
