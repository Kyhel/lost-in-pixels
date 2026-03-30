class_name FleeGoal
extends Goal

func get_score(creature: Creature) -> float:
	if creature.needs_component.get_need_value(NeedIds.FEAR, 0.0) >= FearNeed.FEAR_THRESHOLD:
		return 20.0
	return 0.0
