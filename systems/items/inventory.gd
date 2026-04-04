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
	if not actor.is_in_group(Groups.PLAYER):
		return
	var item: ItemData = PickableBehavior.get_pickup_item(world_object.object_data)
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


## Removes up to [param amount] from the stack at [param slot_index]. Returns how many were removed.
func _remove_from_slot(slot_index: int, amount: int) -> int:
	if slot_index < 0 or slot_index >= SLOT_COUNT or amount <= 0:
		return 0
	var entry: Variant = _slots[slot_index]
	if entry == null or not entry is Dictionary:
		return 0
	var cnt: int = int(entry["count"])
	var take: int = mini(cnt, amount)
	cnt -= take
	if cnt <= 0:
		_slots[slot_index] = null
	else:
		entry["count"] = cnt
	return take


## Removes up to [param amount] of [param item_id] across stacked slots. Returns true if anything was removed.
## Applies all [member ItemData.consume_effects] for the item in [param slot_index], then removes one from that slot. Returns false if invalid, empty, or player cannot consume.
func consume_one_at_slot(slot_index: int, player: Player) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	if player == null or player.is_dead():
		return false
	var entry: Variant = _slots[slot_index]
	if entry == null or not entry is Dictionary:
		return false
	var item_id: StringName = entry.get("id", &"") as StringName
	var data: ItemData = ItemDatabase.get_item_data(item_id)
	if data == null:
		return false
	for e in data.consume_effects:
		if e != null:
			e.apply(player)
	if _remove_from_slot(slot_index, 1) < 1:
		return false
	inventory_changed.emit()
	return true


## Spawns [member ItemData.on_drop_object] in front of the player (same placement rules as grow flower), with [member WorldObject.placed_by_player] set. Removes one from the stack on success.
func drop_one_at_slot(slot_index: int, player: Player) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false
	if player == null or player.is_dead():
		return false
	var entry: Variant = _slots[slot_index]
	if entry == null or not entry is Dictionary:
		return false
	var item_id: StringName = entry.get("id", &"") as StringName
	var data: ItemData = ItemDatabase.get_item_data(item_id)
	if data == null or data.on_drop_object == null:
		return false
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var distance := Player.PICKUP_RADIUS
	var spawn_pos := player.global_position + forward * distance
	if ObjectsManager.is_object_spawn_blocked(spawn_pos, data.on_drop_object):
		return false
	var wo: WorldObject = ObjectsManager.spawn_object_at(data.on_drop_object, spawn_pos, true)
	if wo == null:
		return false
	if _remove_from_slot(slot_index, 1) < 1:
		return false
	inventory_changed.emit()
	return true


func remove_item(item_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	if ItemDatabase.get_item_data(item_id) == null:
		push_warning("Inventory.remove_item: unknown item id '%s'" % String(item_id))
		return false
	var remaining: int = amount
	for i in SLOT_COUNT:
		if remaining <= 0:
			break
		var entry: Variant = _slots[i]
		if entry == null or not entry is Dictionary:
			continue
		if entry.get("id", null) != item_id:
			continue
		var taken: int = _remove_from_slot(i, remaining)
		if taken <= 0:
			continue
		remaining -= taken
		inventory_changed.emit()
	return amount > remaining


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
