extends GenericDatabase


func _init() -> void:
	database_name = "CreatureDatabase"


func _ready() -> void:
	var config: CreatureDatabaseConfig = preload("res://systems/creatures/creature_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for creature in config.creatures:
		_register_creature(creature)


func _register_creature(creature: CreatureData) -> void:
	_register(creature)


func get_creature_data(id: StringName) -> CreatureData:
	return get_by_id(id) as CreatureData
