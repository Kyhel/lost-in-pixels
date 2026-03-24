class_name AbilityUnlockRule
extends Resource

@export var eater_creature: CreatureData
@export var food_object_data: ObjectData
@export var witness_radius: float = 450.0


func matches(eater: Creature, object_data: ObjectData, witness_position: Vector2, player_position: Vector2) -> bool:
	if object_data == null or eater == null or eater.creature_data == null:
		return false
	if eater_creature != null and eater.creature_data != eater_creature:
		return false
	if food_object_data != null:
		if object_data != food_object_data and object_data.id != food_object_data.id:
			return false
	return witness_position.distance_to(player_position) <= witness_radius
