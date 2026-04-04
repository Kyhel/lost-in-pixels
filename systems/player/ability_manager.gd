extends Node

var discovered_order: Array[StringName] = []
var _discovered_set: Dictionary = {}

signal ability_unlocked(ability: AbilityData)
signal discoveries_changed


func _ready() -> void:
	EventManager.object_eaten.connect(_on_object_eaten)


func _on_object_eaten(eater: Creature, world_object: WorldObject) -> void:
	if world_object == null or world_object.object_data == null:
		return
	var player := _get_player()
	if player == null:
		return
	for ability in AbilityDatabase.get_all_ability_data():
		if _discovered_set.has(ability.id):
			continue
		if ability.unlock_rule == null:
			continue
		if ability.unlock_rule.matches(eater, world_object.object_data, player):
			_discover(ability)


func _discover(ability: AbilityData) -> void:
	if _discovered_set.has(ability.id):
		return
	_discovered_set[ability.id] = true
	discovered_order.append(ability.id)
	if not ability.discover_log_message.strip_edges().is_empty():
		var slot_number := discovered_order.size()
		var action_name := StringName("ability_" + str(slot_number))
		var prompt := _get_action_prompt(action_name)
		var message := ability.discover_log_message
		if not prompt.is_empty():
			message += " (Press %s)" % prompt
		GameLog.log_message(message)
	ability_unlocked.emit(ability)
	discoveries_changed.emit()


func try_activate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= discovered_order.size():
		return
	var id: StringName = discovered_order[slot_index]
	var ability: AbilityData = AbilityDatabase.get_ability_data(id)
	if ability == null or ability.effect_script == null:
		return
	var player := _get_player()
	if player == null:
		return
	var inst: Variant = ability.effect_script.new()
	if inst != null and inst.has_method("execute"):
		var result: Variant = inst.execute(player)
		var success: bool = true
		if result is bool:
			success = result as bool
		if success:
			if not ability.use_log_message.strip_edges().is_empty():
				GameLog.log_message(ability.use_log_message)
		else:
			if not ability.failure_log_message.strip_edges().is_empty():
				GameLog.log_message(ability.failure_log_message)


func apply_discovered_from_save(ids: Variant) -> void:
	_discovered_set.clear()
	discovered_order.clear()
	if ids is Array:
		for v in ids:
			var sid := StringName(str(v))
			var ability := AbilityDatabase.get_ability_data(sid)
			if ability != null:
				_discovered_set[sid] = true
				discovered_order.append(sid)
	discoveries_changed.emit()


func get_discovered_ids_for_save() -> Array:
	return discovered_order.duplicate()


func _get_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	var n := tree.get_first_node_in_group(Groups.PLAYER)
	return n as Player


func _get_action_prompt(action_name: StringName) -> String:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return ""
	return (events[0] as InputEvent).as_text().strip_edges()
