extends GenericDatabase


func _init() -> void:
	database_name = "AbilityDatabase"


func _ready() -> void:
	var config: AbilityDatabaseConfig = preload("res://systems/player/ability_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for ability_data in config.abilities:
		_register(ability_data)


func get_ability_data(id: StringName) -> AbilityData:
	return get_by_id(id) as AbilityData


func get_all_ability_data() -> Array:
	return get_all()
