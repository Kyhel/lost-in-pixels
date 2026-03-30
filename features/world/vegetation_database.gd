extends Node

var _vegetation_by_id: Dictionary = {}


func _ready() -> void:
	var config: VegetationDatabaseConfig = preload("res://features/world/vegetation_database_config.tres")
	if config == null:
		push_error("VegetationDatabase: failed to load config resource")
		return
	for spawn_def in config.vegetation_spawn_definitions:
		_register_spawn_definition(spawn_def)


func _register_spawn_definition(spawn_def: VegetationSpawnDefinition) -> void:
	if spawn_def == null:
		return
	var object_data: ObjectData = spawn_def.object_data
	if object_data == null:
		push_warning("VegetationDatabase: VegetationSpawnDefinition has no object_data; skipped.")
		return
	var resolved_id: StringName = object_data.id
	if String(resolved_id).is_empty():
		var path: String = object_data.resource_path
		if path.is_empty():
			push_warning("VegetationDatabase: ObjectData has no id and no resource_path; skipped.")
			return
		resolved_id = StringName(path.get_file().get_basename())
	if String(resolved_id).is_empty():
		push_warning("VegetationDatabase: could not resolve ObjectData id; skipped.")
		return
	if _vegetation_by_id.has(resolved_id):
		push_warning("VegetationDatabase: duplicate vegetation id '%s'; skipping duplicate." % String(resolved_id))
		return
	_vegetation_by_id[resolved_id] = spawn_def


func get_vegetation_spawn_definition(id: StringName) -> VegetationSpawnDefinition:
	return _vegetation_by_id.get(id, null) as VegetationSpawnDefinition


func get_all_vegetation_spawn_definitions() -> Array:
	return _vegetation_by_id.values()
