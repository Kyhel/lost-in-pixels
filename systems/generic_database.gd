class_name GenericDatabase
extends Node

## Base for autoload databases: shared storage, id resolution, and logging via [member database_name].

var database_name: String = "GenericDatabase"

var _entries_by_id: Dictionary = {}


func get_by_id(id: StringName) -> Variant:
	return _entries_by_id.get(id, null)


func get_all() -> Array:
	return _entries_by_id.values()


func _resolve_id_from_resource(data: Resource) -> StringName:
	var resolved_id: StringName = data.get("id")
	if String(resolved_id).is_empty():
		var path: String = data.resource_path
		if path.is_empty():
			push_warning("%s: Resource has no id and no resource_path; skipped." % [database_name])
			return &""
		resolved_id = StringName(path.get_file().get_basename())
		data.set("id", resolved_id)
	if String(resolved_id).is_empty():
		push_warning("%s: could not resolve id; skipped." % [database_name])
		return &""
	return resolved_id


func _register_at_id(resolved_id: StringName, value: Variant) -> void:
	if String(resolved_id).is_empty():
		return
	if _entries_by_id.has(resolved_id):
		push_warning("%s: duplicate id '%s'; skipping duplicate." % [database_name, String(resolved_id)])
		return
	_entries_by_id[resolved_id] = value


## Registers data under its resolved id (sets id from resource path basename when empty).
func _register(data: Resource) -> void:
	if data == null:
		return
	var resolved_id := _resolve_id_from_resource(data)
	_register_at_id(resolved_id, data)
