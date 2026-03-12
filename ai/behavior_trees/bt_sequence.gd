class_name BTSequence
extends BTNode

var current_child := 0

func tick(creature: Creature, delta: float) -> State:

	while current_child < get_child_count():

		var child = get_child(current_child)
		var result = child.tick(creature, delta)

		if result == State.RUNNING:
			return State.RUNNING

		if result == State.FAILURE:
			reset()
			return State.FAILURE

		current_child += 1

	reset()
	return State.SUCCESS

func reset():
	current_child = 0
	super.reset()
