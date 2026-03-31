class_name FetchObjectGoal
extends Goal

const STAMINA_MARGIN: float = 20.0
const STAMINA_MIN: float = clampf(
	FetchWorldObjectAction.FETCH_STAMINA_COST + STAMINA_MARGIN,
	NeedInstance.MIN_VALUE,
	NeedInstance.MAX_VALUE)

const FETCH_DESIRE_MIN: float = 0.8 * NeedInstance.MAX_VALUE

@export var fetch_search_score: float = 10
@export var fetch_return_score: float = 50
@export var hunger_threshold: float = 80.0

func get_score(creature: Creature) -> float:
	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return 0.0

	if creature.is_holding_world_object():
		return fetch_return_score

	var fetchables: Array = creature.blackboard.get_value(Blackboard.KEY_FETCHABLES, [])
	if fetchables == null or fetchables.is_empty():
		return 0.0

	var stamina_ratio := 1.0
	var fetch_desire_ratio := 1.0

	if creature.needs_component == null:
		return fetch_search_score
	var stamina_inst := creature.needs_component.get_instance(NeedIds.STAMINA)
	if stamina_inst != null:
		stamina_ratio = clampf(inverse_lerp(
			STAMINA_MARGIN,
			STAMINA_MIN,
			stamina_inst.current_value
			), 0.0, 1.0)

	var fetch_desire_inst := creature.needs_component.get_instance(NeedIds.FETCH_DESIRE)
	if fetch_desire_inst != null:
		fetch_desire_ratio = clampf(inverse_lerp(
			FETCH_DESIRE_MIN,
			NeedInstance.MAX_VALUE,
			fetch_desire_inst.current_value
			), 0.0, 1.0)

	return fetch_search_score * stamina_ratio * fetch_desire_ratio
