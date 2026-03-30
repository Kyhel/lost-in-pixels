class_name NeedsComponent
extends RefCounted

signal need_value_changed(id: StringName, value: float)

## Keys: [member Need.id], values: [NeedInstance]. Last wins if [member CreatureData.needs] lists duplicate ids.
var instances: Dictionary[StringName, NeedInstance] = {}


func has_any() -> bool:
	return not instances.is_empty()


func get_instance(id: StringName) -> NeedInstance:
	return instances.get(id, null)


func get_need_value(id: StringName, default_value: float = 0.0) -> float:
	var inst: NeedInstance = get_instance(id)
	if inst == null:
		return default_value
	return inst.current_value


func set_need_value(id: StringName, value: float) -> void:
	var inst := get_instance(id)
	if inst == null:
		return
	inst.set_value(value)


func update_all(creature: Creature, delta: float) -> void:
	for k in instances.keys():
		var inst := instances[k]
		if inst == null or inst.need == null:
			continue
		inst.need.update(creature, inst, delta)


static func from_creature_data(creature_data: CreatureData) -> NeedsComponent:
	var nc := NeedsComponent.new()
	if creature_data == null:
		return nc
	for need in creature_data.needs:
		if need == null:
			continue
		var nid: StringName = need.id
		if String(nid).is_empty():
			push_error("Need id is empty: %s" % need)
			continue
		var inst := NeedInstance.new(need)
		inst.value_changed.connect(nc.need_value_changed.emit)
		inst.setup()
		nc.instances[nid] = inst
	return nc
