extends GenericDatabase


func _init() -> void:
	database_name = "AreaEventDatabase"


func _ready() -> void:
	var config: AreaEventDatabaseConfig = load("res://systems/area_events/area_event_database_config.tres")
	if config == null:
		push_error("%s: failed to load config resource" % database_name)
		return
	for ev in config.events:
		_register(ev)


func get_area_event_data(id: StringName) -> AreaEvent:
	return get_by_id(id) as AreaEvent


func trigger(id: StringName, world_position: Vector2) -> void:
	var ev: AreaEvent = get_area_event_data(id)
	if ev == null:
		push_warning("%s: unknown area event id '%s'" % [database_name, String(id)])
		return
	ev.apply(world_position)
