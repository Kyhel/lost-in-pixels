extends Node

var _abilities: Array[AbilityData] = []
var _by_id: Dictionary = {}
var discovered_order: Array[StringName] = []
var _discovered_set: Dictionary = {}

signal ability_unlocked(ability: AbilityData)
signal discoveries_changed


func _ready() -> void:
	_register_abilities()


func _register_abilities() -> void:
	_register(load("res://data/abilities/grow_flower.tres") as AbilityData)


func _register(ability: AbilityData) -> void:
	if ability == null or ability.id == &"":
		return
	_abilities.append(ability)
	_by_id[ability.id] = ability


func get_ability(id: StringName) -> AbilityData:
	return _by_id.get(id, null)


func notify_creature_ate_item(eater: Creature, item: WorldItem) -> void:
	if item == null or item.item_data == null:
		return
	var player := _get_player()
	if player == null:
		return
	var ppos: Vector2 = player.global_position
	for ability in _abilities:
		if _discovered_set.has(ability.id):
			continue
		if ability.unlock_rule == null:
			continue
		if ability.unlock_rule.matches(eater, item.item_data, eater.global_position, ppos):
			_discover(ability)


func _discover(ability: AbilityData) -> void:
	if _discovered_set.has(ability.id):
		return
	_discovered_set[ability.id] = true
	discovered_order.append(ability.id)
	ability_unlocked.emit(ability)
	discoveries_changed.emit()


func try_activate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= discovered_order.size():
		return
	var id: StringName = discovered_order[slot_index]
	var ability: AbilityData = _by_id.get(id, null)
	if ability == null or ability.effect_script == null:
		return
	var player := _get_player()
	if player == null:
		return
	var inst: Variant = ability.effect_script.new()
	if inst != null and inst.has_method("execute"):
		inst.execute(player)


func apply_discovered_from_save(ids: Variant) -> void:
	_discovered_set.clear()
	discovered_order.clear()
	if ids is Array:
		for v in ids:
			var sid := StringName(str(v))
			if _by_id.has(sid):
				_discovered_set[sid] = true
				discovered_order.append(sid)
	discoveries_changed.emit()


func get_discovered_ids_for_save() -> Array:
	return discovered_order.duplicate()


func _get_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	var n := tree.get_first_node_in_group("player")
	return n as Player
