class_name EatFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var target_food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)

	if target_food == null:
		return State.FAILURE

	if target_food.global_position.distance_to(creature.global_position) > 10:
		return State.FAILURE

	for item in ObjectsManager.get_nearby_items(creature.global_position, 10):
		item.on_picked_up(self)

	return State.SUCCESS
