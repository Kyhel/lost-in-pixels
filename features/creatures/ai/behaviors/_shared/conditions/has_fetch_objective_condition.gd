class_name HasFetchObjectiveCondition
extends BTCondition

func condition(creature: Creature) -> bool:
	if creature.is_holding_world_object():
		return true
	var fetchables = creature.blackboard.get_value(Blackboard.KEY_FETCHABLES, [])
	return fetchables != null and not fetchables.is_empty()
