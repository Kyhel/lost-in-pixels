extends GenericDatabase


func _init() -> void:
	database_name = "ObjectDatabase"


func _ready() -> void:
	var config: ObjectDatabaseConfig = preload("res://systems/objects/object_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for object_data in config.objects:
		_register(object_data)


func get_object_data(id: StringName) -> ObjectData:
	return get_by_id(id) as ObjectData
