class_name FetchableBehavior
extends WorldObjectBehavior

@export var fetched_object_data: ObjectData

static func get_fetched_object_data(od: ObjectData) -> ObjectData:
	if od == null:
		return null
	for b in od.behaviors:
		var fetchable := b as FetchableBehavior
		if fetchable == null:
			continue
		if fetchable.fetched_object_data != null:
			return fetchable.fetched_object_data
	return od

static func has_behavior(od: ObjectData) -> bool:
	if od == null:
		return false
	for b in od.behaviors:
		if b is FetchableBehavior:
			return true
	return false
