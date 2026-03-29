class_name PickableBehavior
extends WorldObjectBehavior

@export var item: ItemData


static func get_pickup_item(od: ObjectData) -> ItemData:
	for b in od.behaviors:
		if b is PickableBehavior:
			var pickable := b as PickableBehavior
			if pickable.item != null:
				return pickable.item
	return null


static func has_behavior(wo: WorldObject) -> bool:

	if wo == null or wo.object_data == null:
		return false

	for b in wo.object_data.behaviors:
		if b is PickableBehavior and b.item != null:
			return true
	return false
