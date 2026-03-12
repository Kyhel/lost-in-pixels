class_name BTNode
extends Node

enum State {
	SUCCESS,
	FAILURE,
	RUNNING
}

func tick(_creature: Creature, _delta: float) -> State:
	return State.SUCCESS

func reset():
	for child in get_children():
		if child is BTNode:
			child.reset()
