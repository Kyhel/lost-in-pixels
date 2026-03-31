class_name IsHoldingWorldObjectCondition
extends BTCondition

func condition(creature: Creature) -> bool:
	return creature.is_holding_world_object()
