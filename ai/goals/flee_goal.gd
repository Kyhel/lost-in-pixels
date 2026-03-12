class_name FleeGoal
extends Goal

func get_score(creature):

	var predators = creature.blackboard.get_value(Blackboard.KEY_PREDATORS)

	if predators == null or predators.is_empty():
		return 0

	var predator = predators[0]
	var dist = creature.global_position.distance_to(predator.global_position)

	return (200 / max(dist,1)) * weight
