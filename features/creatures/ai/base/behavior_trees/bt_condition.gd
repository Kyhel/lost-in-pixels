class_name BTCondition
extends BTNode

func condition(_creature: Creature) -> bool:
	return false

func tick(creature: Creature, _delta: float) -> State:
	if condition(creature):
		return State.SUCCESS
	return State.FAILURE
