class_name TamableTrait
extends CreatureTrait

## Maps [ObjectData] resources to taming progress gained when a tamable creature eats that food (player-placed only).
@export var taming_by_food: Dictionary[ObjectData, int] = {}


static func find_on(creature_data: CreatureData) -> TamableTrait:
	if creature_data == null:
		return null
	for t in creature_data.traits:
		if t is TamableTrait:
			return t as TamableTrait
	return null


func get_taming_value_for(object_data: ObjectData) -> int:
	if object_data == null:
		return 0
	var v: Variant = taming_by_food.get(object_data)
	if v is int:
		return v as int
	if v is float:
		return int(v)
	for k in taming_by_food.keys():
		if k is ObjectData and (k as ObjectData).id == object_data.id:
			var v2: Variant = taming_by_food[k]
			if v2 is int:
				return v2 as int
			if v2 is float:
				return int(v2)
	return 0


static func world_object_is_taming_target(creature: Creature, world_object: WorldObject) -> bool:
	if creature == null or creature.creature_data == null:
		return false
	var tamable := find_on(creature.creature_data)
	if tamable == null:
		return false
	if world_object == null or world_object.object_data == null:
		return false
	if not world_object.placed_by_player:
		return false
	return tamable.get_taming_value_for(world_object.object_data) > 0
