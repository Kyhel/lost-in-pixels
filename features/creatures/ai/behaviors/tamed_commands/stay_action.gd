class_name StayAction
extends BTNode


func tick(creature: Creature, _delta: float) -> State:
	creature.movement.stop()
	return State.RUNNING
