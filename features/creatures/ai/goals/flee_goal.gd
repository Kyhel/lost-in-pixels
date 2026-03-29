class_name FleeGoal
extends Goal

func get_score(creature: Creature) -> float:
	if creature.blackboard.get_value(Blackboard.KEY_FEAR, 0.0) >= Blackboard.KEY_FEAR_FLEE_THRESHOLD:
		return 20.0
	return 0.0
