class_name PickableBehavior
extends WorldObjectBehavior

@export var item_id: StringName
@export var requires_night: bool = false


static func get_pickup_item(od: ObjectData) -> ItemData:
	for b in od.behaviors:
		if b is PickableBehavior:
			var pickable := b as PickableBehavior
			if pickable.item_id.is_empty():
				continue
			if pickable.requires_night and not DayNightCycle.is_night_phase():
				continue
			return ItemDatabase.get_item_data(pickable.item_id)
	return null


static func has_behavior(wo: WorldObject) -> bool:

	if wo == null or wo.object_data == null:
		return false

	return get_pickup_item(wo.object_data) != null
