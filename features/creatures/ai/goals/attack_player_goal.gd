class_name AttackPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:

	# Use != true so missing/null is treated as "does not see" (null == false is false in GDScript).
	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER) != true:
		return 0

	if creature.creature_data == null or creature.creature_data.aggressiveness_buildup_rate <= 0.0:
		return 10.0

	var recovering: bool = creature.blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS_RECOVERING) == true
	if recovering:
		return 0.0

	var agg = creature.blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS)
	if agg == null:
		agg = 0.0
	return 10.0 if float(agg) >= 100.0 else 0.0
