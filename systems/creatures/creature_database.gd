extends Node

var _creatures: Dictionary[StringName, CreatureData] = {}

func _ready() -> void:
	var config: CreatureDatabaseConfig = load("res://systems/creatures/creature_database_config.tres")
	for creature in config.creatures:
		_register_creature(creature)

func _register_creature(creature: CreatureData) -> void:
	_creatures[creature.id] = creature

func get_creature_data(id: StringName) -> CreatureData:
	return _creatures.get(id, null)
