class_name NeedsComponent
extends RefCounted

signal need_value_changed(id: StringName, value: float)

## Keys: [member Need.id], values: [NeedInstance]. Last wins if [member CreatureData.needs] lists duplicate ids.
var instances: Dictionary[StringName, NeedInstance] = {}


func _init(creature_data: CreatureData = null) -> void:
	if creature_data == null:
		return
	for need in creature_data.needs:
		if need == null:
			continue
		var nid: StringName = need.id
		if String(nid).is_empty():
			push_error("Need id is empty: %s" % need)
			continue
		var inst := NeedInstance.new(need)
		inst.value_changed.connect(need_value_changed.emit)
		inst.setup()
		instances[nid] = inst


func get_need(id: StringName) -> Need:
	var inst := get_instance(id)
	if inst == null:
		return null
	return inst.need


func has_any() -> bool:
	return not instances.is_empty()


func get_instance(id: StringName) -> NeedInstance:
	return instances.get(id, null)


func get_need_value(id: StringName, default_value: float = 0.0) -> float:
	var inst: NeedInstance = get_instance(id)
	if inst == null:
		return default_value
	return inst.current_value


func get_need_value_or_null(id: StringName) -> Variant:
	var inst := get_instance(id)
	if inst == null:
		return null
	return inst.current_value


func set_need_value(id: StringName, value: float) -> void:
	var inst := get_instance(id)
	if inst == null:
		return
	inst.set_value(value)


func update_all(p_creature: Creature, delta: float) -> void:
	for k in instances.keys():
		var inst := instances[k]
		if inst == null or inst.need == null:
			continue
		inst.need.update(p_creature, inst, delta)
