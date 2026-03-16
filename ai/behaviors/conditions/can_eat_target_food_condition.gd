extends BTCondition
class_name CanEatTargetFoodCondition

func condition(creature: Creature) -> bool:
	var target_food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)
	return target_food != null and is_instance_valid(target_food) and target_food.global_position.distance_to(creature.global_position) <= 10
