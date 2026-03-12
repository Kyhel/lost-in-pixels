class_name ChooseFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)

	if foods == null or foods.is_empty():
		return State.FAILURE

	creature.blackboard.set_value(Blackboard.KEY_TARGET_FOOD, foods[0])

	return State.SUCCESS
