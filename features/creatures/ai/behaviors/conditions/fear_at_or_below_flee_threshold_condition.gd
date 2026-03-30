extends BTCondition
class_name FearAtOrBelowFleeThresholdCondition

func condition(creature: Creature) -> bool:
	return creature.get_need_value(NeedIds.FEAR, 0.0) <= Blackboard.KEY_FEAR_FLEE_THRESHOLD
