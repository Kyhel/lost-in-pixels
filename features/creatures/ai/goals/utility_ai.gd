class_name UtilityAI

static func choose_goal(creature: Creature) -> Goal:

	var best_goal = null
	var best_score = -INF

	for goal in creature.goals:

		var score = goal.get_score(creature)

		if score > best_score:
			best_score = score
			best_goal = goal

	return best_goal
