class_name EatGoal
extends Goal

func get_score(creature):

	if creature.blackboard.get_value(Blackboard.KEY_STATE) == Blackboard.State.EATING:
		return 10

	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)

	if foods == null or foods.is_empty():
		return 0

	var hunger = creature.blackboard.get_value(Blackboard.KEY_HUNGER)
	
	if hunger != null and hunger <= 80:
		return 1.0

	return 0.0
