extends BTCondition
class_name FearAtOrBelowFleeThresholdCondition

func condition(creature: Creature) -> bool:
	return creature.needs_component.get_need_value(NeedIds.FEAR, 0.0) <= FearNeed.FEAR_THRESHOLD
