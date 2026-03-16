class_name WaitAction
extends BTNode

@export var max_wait_time: float = 4.0
@export var min_wait_time: float = 1.0
var timer: float = 0.0
var is_waiting: bool = false

func tick(_creature: Creature, _delta: float) -> State:

	if not is_waiting:
		is_waiting = true
		timer = randf_range(min_wait_time, max_wait_time)
		return State.RUNNING

	if timer < 0:
		is_waiting = false
		return State.SUCCESS

	timer -= _delta
	return State.RUNNING
