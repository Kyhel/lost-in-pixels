extends BTCondition
class_name IsTamedCondition

func condition(creature: Creature) -> bool:
	return creature.blackboard.get_value(Blackboard.KEY_TAMED) == true
