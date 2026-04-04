extends GenericDatabase


func _init() -> void:
	database_name = "VegetationDatabase"


func _ready() -> void:
	var config: VegetationDatabaseConfig = preload("res://features/world_generation/vegetation/vegetation_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for spawn_def in config.vegetation_spawn_definitions:
		_register_spawn_definition(spawn_def)


func _register_spawn_definition(spawn_def: VegetationSpawnDefinition) -> void:
	if spawn_def == null:
		return
	var object_data: ObjectData = spawn_def.object_data
	if object_data == null:
		push_warning("%s: VegetationSpawnDefinition has no object_data; skipped." % database_name)
		return
	var resolved_id := _resolve_id_from_resource(object_data)
	_register_at_id(resolved_id, spawn_def)


func get_vegetation_spawn_definition(id: StringName) -> VegetationSpawnDefinition:
	return get_by_id(id) as VegetationSpawnDefinition


func get_all_vegetation_spawn_definitions() -> Array:
	return get_all()
