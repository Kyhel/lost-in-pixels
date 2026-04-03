class_name TargetFoodIsWorldObjectCondition
extends BTCondition

func condition(creature: Creature) -> bool:
	var target = creature.blackboard.get_value(Blackboard.KEY_TARGET_OBJECT)
	return is_instance_valid(target) and target is WorldObject
