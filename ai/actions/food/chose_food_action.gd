class_name ChooseFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)

	if foods == null:
		return State.FAILURE

	var nodes: Array[Node2D] = []
	for f in foods:
		if is_instance_valid(f):
			nodes.append(f)

	if nodes.is_empty():
		return State.FAILURE
	
	var closest_food = Node2DUtils.get_closest(creature.global_position, nodes)

	creature.blackboard.set_value(Blackboard.KEY_TARGET_FOOD, closest_food)

	return State.SUCCESS
