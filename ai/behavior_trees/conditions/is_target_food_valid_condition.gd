extends BTCondition
class_name IsTargetFoodValidCondition

func condition(creature: Creature) -> bool:
	var target_food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)
	return target_food != null and is_instance_valid(target_food)
