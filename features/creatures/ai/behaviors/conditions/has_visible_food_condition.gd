extends BTCondition
class_name HasVisibleFoodCondition

func condition(creature: Creature) -> bool:
	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)
	return foods != null and not foods.is_empty()
