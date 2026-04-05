class_name HeelCommandGoal
extends Goal

func get_score(creature: Creature) -> float:
	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return 0.0
	var cmd: int = int(creature.blackboard.get_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE))
	if cmd != TameCommand.Kind.HEEL:
		return 0.0
	return TameCommand.ACTIVE_SCORE
