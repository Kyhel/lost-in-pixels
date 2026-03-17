class_name MovementComponent
extends Node

var current_request: MovementRequest = null

var _strategy: MovementStrategy
var _cached_strategy_for_type: int = -1  ## MovementRequest.MovementType we cached for; -1 = none

var _walk_strategy_priority: Array[CreatureData.MovementType] = [
	CreatureData.MovementType.HOP,
	CreatureData.MovementType.DEFAULT,
	CreatureData.MovementType.WALK
]

func set_strategy(creature: Creature) -> void:
	_strategy = _resolve_strategy(creature, MovementRequest.MovementType.WALK)
	_cached_strategy_for_type = MovementRequest.MovementType.WALK if _strategy != null else -1
	if _strategy == null and creature.creature_data.movement_types.size() > 0:
		var first_type = creature.creature_data.movement_types[0]
		_strategy = MovementStrategyDatabase.get_strategy(first_type)
		if _strategy != null:
			_strategy = _strategy.duplicate()
			_cached_strategy_for_type = MovementRequest.MovementType.WALK

func request_movement(request: MovementRequest) -> void:
	current_request = request

func stop() -> void:
	current_request = null
	_cached_strategy_for_type = -1
	if _strategy != null:
		_strategy.reset()

func update_movement(creature: Creature, delta: float) -> void:

	if current_request == null:
		creature.velocity = Vector2.ZERO
		return

	if creature.creature_data == null:
		return

	# Resolve strategy for this request type (cache per request type to keep strategy state)
	if _cached_strategy_for_type != current_request.movement_type:
		_strategy = _resolve_strategy(creature, current_request.movement_type)
		_cached_strategy_for_type = current_request.movement_type
		if _strategy != null:
			_strategy.reset()

	if _strategy == null:
		return

	_strategy.move(creature, current_request.target_position, delta)

## Returns a duplicated strategy instance for the given request type and creature's available movement_types.
func _resolve_strategy(creature: Creature, request_movement_type: int) -> MovementStrategy:
	var types: Array = creature.creature_data.movement_types
	if types.is_empty():
		return null

	match request_movement_type:
		MovementRequest.MovementType.WALK:
			for priority_type in _walk_strategy_priority:
				if priority_type in types:
					var strat = MovementStrategyDatabase.get_strategy(priority_type)
					return strat.duplicate() if strat != null else null
			return null
		MovementRequest.MovementType.RUN, MovementRequest.MovementType.SPRINT:
			if CreatureData.MovementType.RUN in types:
				var run_strat = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.RUN)
				return run_strat.duplicate() if run_strat != null else null
			# Fall through to first available
		_:
			pass

	# No match or SNEAK/other: use first available strategy for this creature
	var first_type = types[0]
	var fallback_strat = MovementStrategyDatabase.get_strategy(first_type)
	return fallback_strat.duplicate() if fallback_strat != null else null
