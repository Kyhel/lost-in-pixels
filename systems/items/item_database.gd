extends Node

var _item_data_by_id: Dictionary = {}


func _ready() -> void:
	var config: ItemDatabaseConfig = preload("res://systems/items/item_database_config.tres")
	if config == null:
		push_error("ItemDatabase: failed to load config resource")
		return
	for item_data in config.items:
		_register_item_data(item_data)


func _register_item_data(data: ItemData) -> void:
	if data == null:
		return
	var resolved_id: StringName = data.id
	if String(resolved_id).is_empty():
		var path: String = data.resource_path
		if path.is_empty():
			push_warning("ItemDatabase: ItemData has no id and no resource_path; skipped.")
			return
		resolved_id = StringName(path.get_file().get_basename())
		data.id = resolved_id
	if String(resolved_id).is_empty():
		push_warning("ItemDatabase: could not resolve ItemData id; skipped.")
		return
	if _item_data_by_id.has(resolved_id):
		push_warning("ItemDatabase: duplicate item id '%s'; skipping duplicate." % String(resolved_id))
		return
	_item_data_by_id[resolved_id] = data


func get_item_data(id: StringName) -> ItemData:
	return _item_data_by_id.get(id, null)


func get_all_item_data() -> Array:
	return _item_data_by_id.values()
