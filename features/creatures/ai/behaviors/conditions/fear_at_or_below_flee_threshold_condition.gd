extends BTCondition
class_name FearAtOrBelowFleeThresholdCondition

func condition(creature: Creature) -> bool:
	return creature.blackboard.get_value(Blackboard.KEY_FEAR, 0.0) <= Blackboard.KEY_FEAR_FLEE_THRESHOLD
