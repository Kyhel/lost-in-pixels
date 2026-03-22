class_name AbilityUnlockRule
extends Resource

@export var eater_creature: CreatureData
@export var food_item: ItemData
@export var witness_radius: float = 450.0


func matches(eater: Creature, item_data: ItemData, witness_position: Vector2, player_position: Vector2) -> bool:
	if item_data == null or eater == null or eater.creature_data == null:
		return false
	if eater_creature != null and eater.creature_data != eater_creature:
		return false
	if food_item != null:
		if item_data != food_item and item_data.id != food_item.id:
			return false
	return witness_position.distance_to(player_position) <= witness_radius
