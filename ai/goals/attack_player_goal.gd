class_name AttackPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:

	# Use != true so missing/null is treated as "does not see" (null == false is false in GDScript).
	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER) != true:
		return 0

	return 10.0
