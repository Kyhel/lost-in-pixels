class_name ChooseFetchableAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	var fetchables = creature.blackboard.get_value(Blackboard.KEY_FETCHABLES, [])
	if fetchables == null:
		return State.FAILURE

	var valid_nodes: Array[Node2D] = []
	for node in fetchables:
		if is_instance_valid(node) and node is WorldObject:
			valid_nodes.append(node)

	if valid_nodes.is_empty():
		return State.FAILURE

	var closest = Node2DUtils.get_closest(creature.global_position, valid_nodes)
	creature.blackboard.set_value(Blackboard.KEY_TARGET_FETCHABLE, closest)
	return State.SUCCESS
