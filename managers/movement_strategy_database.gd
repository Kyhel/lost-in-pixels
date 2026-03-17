extends Node

var _movement_strategies_by_type: Dictionary = {}

func _ready() -> void:
	_register_defaults()


func _register_defaults() -> void:
	_register_strategy(CreatureData.MovementType.HOP, load("res://data/actors/movement/hop_movement_strategy.tres"))
	_register_strategy(CreatureData.MovementType.DEFAULT, load("res://data/actors/movement/default_movement_strategy.tres"))
	_register_strategy(CreatureData.MovementType.WALK, load("res://data/actors/movement/walk_movement_strategy.tres"))
	_register_strategy(CreatureData.MovementType.RUN, load("res://data/actors/movement/run_movement_strategy.tres"))
	_register_strategy(CreatureData.MovementType.SPRINT, load("res://data/actors/movement/sprint_movement_strategy.tres"))

func _register_strategy(movement_type: CreatureData.MovementType, strategy: MovementStrategy) -> void:
	if strategy == null:
		return
	_movement_strategies_by_type[movement_type] = strategy

func get_strategy(movement_type: CreatureData.MovementType) -> MovementStrategy:
	return _movement_strategies_by_type.get(movement_type, null)
