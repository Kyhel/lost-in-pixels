extends GenericDatabase


func _init() -> void:
	database_name = "ItemDatabase"


func _ready() -> void:
	var config: ItemDatabaseConfig = load("res://systems/items/item_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for item_data in config.items:
		_register(item_data)


func get_item_data(id: StringName) -> ItemData:
	return get_by_id(id) as ItemData
