class_name FollowPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:
	if creature.blackboard.get_value(Blackboard.KEY_TAMED) == true:
		return 0.5
	return 0.0
