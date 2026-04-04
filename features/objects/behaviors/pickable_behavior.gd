class_name PickableBehavior
extends WorldObjectBehavior

@export var item_id: StringName


static func get_pickup_item(od: ObjectData) -> ItemData:
	for b in od.behaviors:
		if b is PickableBehavior:
			var pickable := b as PickableBehavior
			if not pickable.item_id.is_empty():
				return ItemDatabase.get_item_data(pickable.item_id)
	return null


static func has_behavior(wo: WorldObject) -> bool:

	if wo == null or wo.object_data == null:
		return false

	for b in wo.object_data.behaviors:
		if b is PickableBehavior:
			var pickable := b as PickableBehavior
			if not pickable.item_id.is_empty():
				return true
	return false
