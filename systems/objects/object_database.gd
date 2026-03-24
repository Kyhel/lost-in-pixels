extends Node

const _CONFIG_SCRIPT: GDScript = preload("res://systems/objects/object_database_config.gd")

var _object_data_by_id: Dictionary = {}

func _ready() -> void:
	var config: ObjectDatabaseConfig = preload("res://systems/objects/object_database_config.tres")
	if config == null:
		push_error("ObjectDatabase: failed to load config resource")
		return
	for object_data in config.objects:
		_register_object_data(object_data)


func _register_object_data(data: ObjectData) -> void:
	if data == null:
		return
	var resolved_id: StringName = data.id
	if String(resolved_id).is_empty():
		var path := data.resource_path
		if path.is_empty():
			push_warning("ObjectDatabase: ObjectData has no id and no resource_path; skipped.")
			return
		resolved_id = StringName(path.get_file().get_basename())
		data.id = resolved_id
	if String(resolved_id).is_empty():
		push_warning("ObjectDatabase: could not resolve ObjectData id; skipped.")
		return
	if _object_data_by_id.has(resolved_id):
		push_warning("ObjectDatabase: duplicate object id '%s'; skipping duplicate." % String(resolved_id))
		return
	_object_data_by_id[resolved_id] = data


func get_object_data(id: StringName) -> ObjectData:
	return _object_data_by_id.get(id, null)

func get_all_object_data() -> Array:
	return _object_data_by_id.values()
