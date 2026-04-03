class_name TargetFoodIsCreatureCondition
extends BTCondition

func condition(creature: Creature) -> bool:
	var target = creature.blackboard.get_value(Blackboard.KEY_TARGET_CREATURE)
	return is_instance_valid(target) and target is Creature
