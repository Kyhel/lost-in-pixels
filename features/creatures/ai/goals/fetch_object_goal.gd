class_name FetchObjectGoal
extends Goal

const STAMINA_MAX: float = NeedInstance.MAX_VALUE
const FETCH_STAMINA_COST: float = FetchWorldObjectAction.FETCH_STAMINA_COST

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

	if creature.needs_component == null:
		return fetch_search_score
	var stamina_inst := creature.needs_component.get_instance(NeedIds.STAMINA)
	if stamina_inst == null:
		return fetch_search_score

	var stamina_ratio := clampf(inverse_lerp(STAMINA_MAX, STAMINA_MAX  - FETCH_STAMINA_COST, stamina_inst.current_value), 0.0, 1.0)
	return fetch_search_score * stamina_ratio
