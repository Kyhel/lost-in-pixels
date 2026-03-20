class_name AttackPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:

	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER) == false:
		return 0

	return 10.0
