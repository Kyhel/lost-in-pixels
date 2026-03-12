class_name EatGoal
extends Goal

func get_score(creature):

	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)

	if foods == null or foods.is_empty():
		return 0

	# var hunger = creature.needs.hunger
	# var closest = foods.get_closest_position(creature.global_position)

	# var food_position := foods[0] as Vector2;

	# food_position.get(creature.global_position)

	# var dist = creature.global_position.distance_to(closest.global_position)

	# return hunger * (1.0 / max(dist,1)) * weight
	return 1.0
