class_name TraderTrait
extends CreatureTrait

## Maps received [ItemData] to reward [ItemData] when the player gives an item via creature interaction (1:1).
@export var trades: Dictionary[ItemData, ItemData] = {}


static func find_on(creature_data: CreatureData) -> TraderTrait:
	if creature_data == null:
		return null
	for t in creature_data.traits:
		if t is TraderTrait:
			return t as TraderTrait
	return null


func get_reward_for_received(item_data: ItemData) -> ItemData:
	if item_data == null:
		return null
	var v: Variant = trades.get(item_data)
	if v is ItemData:
		return v as ItemData
	for k in trades.keys():
		if k is ItemData and (k as ItemData).id == item_data.id:
			var v2: Variant = trades[k]
			if v2 is ItemData:
				return v2 as ItemData
	return null
