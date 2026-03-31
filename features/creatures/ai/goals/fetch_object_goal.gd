class_name FetchObjectGoal
extends Goal

@export var fetch_search_score: float = 0.3
@export var fetch_return_score: float = 1.2
@export var hunger_threshold: float = 80.0

func get_score(creature: Creature) -> float:
	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return 0.0

	if creature.is_holding_world_object():
		return fetch_return_score

	var hunger: Variant = creature.needs_component.get_need_value_or_null(NeedIds.HUNGER)
	if hunger != null and hunger <= hunger_threshold:
		return 0.0

	var fetchables: Array = creature.blackboard.get_value(Blackboard.KEY_FETCHABLES, [])
	if fetchables == null or fetchables.is_empty():
		return 0.0

	return fetch_search_score
