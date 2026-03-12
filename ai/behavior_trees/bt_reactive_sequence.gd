class_name BTReactiveSequence
extends BTNode


func tick(creature: Creature, delta: float) -> State:

	for child in get_children():

		var node := child as BTNode
		if node == null:
			continue

		var result := node.tick(creature, delta)

		match result:
			State.SUCCESS:
				continue

			State.RUNNING:
				return State.RUNNING

			State.FAILURE:
				return State.FAILURE

	return State.SUCCESS


func reset():
	for child in get_children():
		if child is BTNode:
			child.reset()
