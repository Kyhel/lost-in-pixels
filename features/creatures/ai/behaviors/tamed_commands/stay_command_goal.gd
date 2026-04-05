class_name StayCommandGoal
extends Goal

func get_score(creature: Creature) -> float:
	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return 0.0
	var cmd: int = int(creature.blackboard.get_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE))
	if cmd != TameCommand.Kind.STAY:
		return 0.0
	if _stay_time_remaining_ms(creature) <= 0:
		return 0.0
	return TameCommand.ACTIVE_SCORE


func update(creature: Creature, _delta: float) -> void:
	_expire_stay_if_needed(creature)


func _stay_time_remaining_ms(creature: Creature) -> int:
	var end_ms: Variant = creature.blackboard.get_value(Blackboard.KEY_STAY_END_TIME_MS)
	if end_ms == null:
		return 0
	return int(end_ms) - Time.get_ticks_msec()


func _expire_stay_if_needed(creature: Creature) -> void:
	if creature.blackboard.get_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE) != TameCommand.Kind.STAY:
		return
	var end_ms: Variant = creature.blackboard.get_value(Blackboard.KEY_STAY_END_TIME_MS)
	if end_ms == null:
		creature.blackboard.set_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE)
		return
	if _stay_time_remaining_ms(creature) > 0:
		return
	creature.blackboard.set_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE)
	creature.blackboard.clear(Blackboard.KEY_STAY_END_TIME_MS)
