class_name BTSelector
extends BTNode

var current_child := 0

func tick(creature: Creature, delta: float) -> State:

	while current_child < get_child_count():
		
		var child: BTNode = get_child(current_child)
		var result = child.tick(creature, delta)

		match result:
			State.SUCCESS:
				reset()
				return State.SUCCESS

			State.RUNNING:
				return State.RUNNING

			State.FAILURE:
				current_child += 1

	reset()
	return State.FAILURE

func reset():
	current_child = 0
	super.reset()
