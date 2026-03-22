extends Node

var _movement_strategies_by_type: Dictionary = {}
var _movement_profiles_by_context: Dictionary = {}

func _ready() -> void:

	var config : MovementDatabaseConfig = load("res://systems/movement_database_config.tres")

	for profile in config.movement_profiles:
		_register_profile(profile.context, profile)
	for strategy in config.movement_strategies:
		_register_strategy(strategy.movement_type, strategy)

func _register_strategy(movement_type: CreatureData.MovementType, strategy: MovementStrategy) -> void:
	if strategy == null:
		return
	_movement_strategies_by_type[movement_type] = strategy

func _register_profile(context: MovementRequest.MovementContext, profile: MovementProfile) -> void:
	if profile == null:
		return
	_movement_profiles_by_context[context] = profile

func get_strategy(movement_type: CreatureData.MovementType) -> MovementStrategy:
	return _movement_strategies_by_type.get(movement_type, null)

func get_profile(context: MovementRequest.MovementContext) -> MovementProfile:
	return _movement_profiles_by_context.get(context, null)
