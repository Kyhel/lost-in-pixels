extends Node

const SLOT_COUNT := 32

signal inventory_changed

var _slots: Array = []


func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(null)
	EventManager.object_picked_up.connect(_on_object_picked_up)


func _on_object_picked_up(actor: Node, world_object: WorldObject) -> void:
	if world_object == null or world_object.object_data == null:
		return
	if not actor.is_in_group("player"):
		return
	var item: ItemData = world_object.object_data.on_pickup_item
	if item == null:
		return
	add_item(item.id, 1)


func add_item(item_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	if ItemDatabase.get_item_data(item_id) == null:
		push_warning("Inventory: unknown item id '%s'" % String(item_id))
		return
	for i in SLOT_COUNT:
		var entry: Variant = _slots[i]
		if entry != null and entry is Dictionary:
			if entry.get("id", null) == item_id:
				entry["count"] = int(entry["count"]) + amount
				inventory_changed.emit()
				return
	for j in SLOT_COUNT:
		if _slots[j] == null:
			_slots[j] = {"id": item_id, "count": amount}
			inventory_changed.emit()
			return
	push_warning("Inventory: no free slot for item '%s'; lost %d" % [String(item_id), amount])


func get_slot(slot_index: int) -> Variant:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return null
	return _slots[slot_index]


func reset() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(null)
	inventory_changed.emit()


func serialize_for_save() -> Array:
	var out: Array = []
	out.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		var e: Variant = _slots[i]
		if e == null:
			out[i] = null
		elif e is Dictionary:
			var d: Dictionary = e
			out[i] = {"id": String(d.get("id", "")), "count": int(d.get("count", 0))}
		else:
			out[i] = null
	return out


func apply_from_save(saved: Variant) -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(null)
	if not saved is Array:
		inventory_changed.emit()
		return
	var arr: Array = saved
	var n: int = mini(SLOT_COUNT, arr.size())
	for i in n:
		var entry: Variant = arr[i]
		if entry == null:
			continue
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var id_str: String = str(d.get("id", ""))
		if id_str.is_empty():
			continue
		var id: StringName = StringName(id_str)
		var cnt: int = int(d.get("count", 0))
		if cnt <= 0:
			continue
		if ItemDatabase.get_item_data(id) == null:
			push_warning("Inventory: save references unknown item '%s'; skipping slot" % id_str)
			continue
		_slots[i] = {"id": id, "count": cnt}
	inventory_changed.emit()
