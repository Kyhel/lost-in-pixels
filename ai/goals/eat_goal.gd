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

	# Not hungry but go for food with taming value if creature can be tamed
	if creature.creature_data != null and creature.creature_data.taming_value_threshold > 0:
		if _has_food_with_taming_value(foods):
			return 1.0

	return 0.0


func _has_food_with_taming_value(foods) -> bool:
	for f in foods:
		if not is_instance_valid(f):
			continue
		if f is WorldItem and f.item_data != null and f.item_data.taming_value > 0:
			return true
	return false
