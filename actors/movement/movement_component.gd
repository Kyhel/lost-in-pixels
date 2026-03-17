class_name MovementComponent
extends Node

var current_request: MovementRequest = null

var _strategy: MovementStrategy
var _cached_strategy_for_type: int = -1  ## CreatureData.MovementType we cached for; -1 = none
var _strategy_cache: Dictionary = {}  ## CreatureData.MovementType -> MovementStrategy (reuse instances per request type)

## Priority order: default < sneak < walk < hop < run < sprint. Used to resolve strategy when exact match isn't available.
var _movement_type_priority: Array[CreatureData.MovementType] = [
	CreatureData.MovementType.DEFAULT,
	CreatureData.MovementType.SNEAK,
	CreatureData.MovementType.WALK,
	CreatureData.MovementType.HOP,
	CreatureData.MovementType.RUN,
	CreatureData.MovementType.SPRINT
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
	var request_type := current_request.movement_type
	if _cached_strategy_for_type != request_type:
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
## Tries the strategy matching the request type; if the creature doesn't have it, uses first available type from
## _movement_type_priority (downgrading from requested level). Falls back to DefaultStrategy when nothing is found.
func _resolve_strategy(creature: Creature, request_movement_type: CreatureData.MovementType) -> MovementStrategy:
	var types: Array = creature.creature_data.movement_types
	if types.is_empty():
		return _get_default_strategy_or_null()

	if request_movement_type in types:
		var strat := MovementStrategyDatabase.get_strategy(request_movement_type)
		return strat.duplicate() if strat != null else _get_default_strategy_or_null()

	# No exact match: use first type from priority list that the creature has (downgrade from requested level)
	var requested_idx: int = _movement_type_priority.find(request_movement_type)
	if requested_idx < 0:
		requested_idx = _movement_type_priority.size()
	for i in range(requested_idx - 1, -1, -1):
		var priority_type: CreatureData.MovementType = _movement_type_priority[i]
		if priority_type in types:
			var strat := MovementStrategyDatabase.get_strategy(priority_type)
			return strat.duplicate() if strat != null else _get_default_strategy_or_null()

	return _get_default_strategy_or_null()

func _get_default_strategy_or_null() -> MovementStrategy:
	var s = MovementStrategyDatabase.get_strategy(CreatureData.MovementType.DEFAULT)
	return s.duplicate() if s != null else null
