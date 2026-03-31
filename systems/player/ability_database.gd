extends Node

var _ability_data_by_id: Dictionary = {}


func _ready() -> void:
	var config : AbilityDatabaseConfig = preload("res://systems/player/ability_database_config.tres")
	if config == null:
		push_error("AbilityDatabase: failed to load config resource")
		return
	for ability_data in config.abilities:
		_register_ability_data(ability_data)


func _register_ability_data(data: AbilityData) -> void:
	if data == null:
		return
	var resolved_id: StringName = data.id
	if String(resolved_id).is_empty():
		var path: String = data.resource_path
		if path.is_empty():
			push_warning("AbilityDatabase: AbilityData has no id and no resource_path; skipped.")
			return
		resolved_id = StringName(path.get_file().get_basename())
		data.id = resolved_id
	if String(resolved_id).is_empty():
		push_warning("AbilityDatabase: could not resolve AbilityData id; skipped.")
		return
	if _ability_data_by_id.has(resolved_id):
		push_warning("AbilityDatabase: duplicate ability id '%s'; skipping duplicate." % String(resolved_id))
		return
	_ability_data_by_id[resolved_id] = data


func get_ability_data(id: StringName) -> AbilityData:
	return _ability_data_by_id.get(id, null)


func get_all_ability_data() -> Array:
	return _ability_data_by_id.values()
