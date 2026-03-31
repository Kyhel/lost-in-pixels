class_name TargetFoodIsCreatureCondition
extends BTCondition

func condition(creature: Creature) -> bool:
	var target = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)
	return target is Creature and is_instance_valid(target)
