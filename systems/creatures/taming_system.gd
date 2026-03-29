extends Node


func _ready() -> void:
	EventManager.object_eaten.connect(_on_object_eaten)


func _on_object_eaten(eater: Creature, world_object: WorldObject) -> void:
	if eater == null or eater.creature_data == null:
		return
	var cd: CreatureData = eater.creature_data
	if cd.taming_value_threshold <= 0:
		return
	if world_object == null or world_object.object_data == null:
		return
	var od: ObjectData = world_object.object_data
	if od.taming_value <= 0:
		return

	var was_tamed: bool = eater.blackboard.get_value(Blackboard.KEY_TAMED) == true
	var taming: Variant = eater.blackboard.get_value(Blackboard.KEY_TAMING)
	if taming == null:
		taming = 0
	taming = int(taming) + od.taming_value
	eater.blackboard.set_value(Blackboard.KEY_TAMING, taming)

	var now_tamed: bool = taming >= cd.taming_value_threshold
	if now_tamed:
		eater.blackboard.set_value(Blackboard.KEY_TAMED, true)

	if was_tamed:
		return

	var creature_name := _creature_display_name(eater)
	var object_name := _object_display_name(od)

	if now_tamed:
		eater.add_to_group(Constants.GROUP_TAMED_CREATURES)
		GameLog.log_message(
			"The %s appreciated eating the %s, it's now following you" % [creature_name, object_name]
		)
	else:
		GameLog.log_message("The %s appreciated eating the %s" % [creature_name, object_name])


func _creature_display_name(creature: Creature) -> String:
	if creature.creature_data != null:
		var dn: String = creature.creature_data.display_name.strip_edges()
		if not dn.is_empty():
			return dn
	return "something"


func _object_display_name(object_data: ObjectData) -> String:
	var dn: String = object_data.display_name.strip_edges()
	if not dn.is_empty():
		return dn
	if not String(object_data.id).is_empty():
		return str(object_data.id)
	return "something"
