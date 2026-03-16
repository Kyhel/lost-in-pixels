class_name BTRecheck
extends BTNode

var condition : BTCondition
var child : BTNode


func _ready():
	if get_child_count() < 2:
		push_error("Recheck needs a condition and a child node")
		return

	assert(get_child(0) is BTCondition, "First child must be a condition")
	assert(get_child(1) is BTNode, "Second child must be a node")

	condition = get_child(0) as BTCondition
	child = get_child(1) as BTNode


func tick(creature: Creature, delta: float) -> State:

	if condition.tick(creature, delta) == State.FAILURE:
		child.reset()
		return State.FAILURE

	return child.tick(creature, delta)


func reset():
	child.reset()
	condition.reset()
