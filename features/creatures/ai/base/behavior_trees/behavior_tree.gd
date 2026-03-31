extends Node

func tick(creature: Creature, delta: float) -> void:

	if get_child_count() == 0:
		return

	var root = get_child(0) as BTNode

	if root.tick(creature, delta) != BTNode.State.RUNNING:
		root.reset()

func reset() -> void:

	if get_child_count() == 0:
		return

	var root = get_child(0) as BTNode

	root.reset()
