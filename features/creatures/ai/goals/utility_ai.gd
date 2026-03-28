class_name UtilityAI

## Picks the highest [method Goal.get_score] among [member CreatureData.goals] keys; switching policy is in [AIRoot].
static func choose_goal(creature: Creature) -> Goal:

	var best_goal = null
	var best_score = -INF

	if creature.creature_data == null:
		return null

	for goal in creature.creature_data.goals:

		var score = goal.get_score(creature)

		if score > best_score:
			best_score = score
			best_goal = goal

	return best_goal
