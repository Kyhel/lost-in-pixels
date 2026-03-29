extends Node

var _vegetation_by_id: Dictionary = {}


func _ready() -> void:
	var config: VegetationDatabaseConfig = preload("res://features/world/vegetation_database_config.tres")
	if config == null:
		push_error("VegetationDatabase: failed to load config resource")
		return
	for veg_data in config.vegetation:
		_register_vegetation_data(veg_data)


func _register_vegetation_data(data: VegetationData) -> void:
	if data == null:
		return
	var spawn_def: VegetationSpawnDefinition = data.vegetation_spawn_definition
	if spawn_def == null:
		push_warning("VegetationDatabase: VegetationData has no vegetation_spawn_definition; skipped.")
		return
	var resolved_id: StringName = data.id
	if String(resolved_id).is_empty():
		var path: String = data.resource_path
		if path.is_empty():
			push_warning("VegetationDatabase: VegetationData has no id and no resource_path; skipped.")
			return
		resolved_id = StringName(path.get_file().get_basename())
		data.id = resolved_id
	if String(resolved_id).is_empty():
		push_warning("VegetationDatabase: could not resolve VegetationData id; skipped.")
		return
	if _vegetation_by_id.has(resolved_id):
		push_warning("VegetationDatabase: duplicate vegetation id '%s'; skipping duplicate." % String(resolved_id))
		return
	_vegetation_by_id[resolved_id] = spawn_def


func get_vegetation_spawn_definition(id: StringName) -> VegetationSpawnDefinition:
	return _vegetation_by_id.get(id, null) as VegetationSpawnDefinition


func get_all_vegetation_spawn_definitions() -> Array:
	return _vegetation_by_id.values()
