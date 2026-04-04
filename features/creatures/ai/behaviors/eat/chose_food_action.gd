class_name ChooseFoodAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:

	var foods = creature.blackboard.get_value(Blackboard.KEY_FOOD)

	if foods == null:
		return State.FAILURE

	var nodes: Array[Node2D] = []
	for f in foods:
		if is_instance_valid(f):
			nodes.append(f)

	if nodes.is_empty():
		return State.FAILURE

	var candidates: Array[Node2D] = _get_food_candidates(creature, nodes)
	if candidates.is_empty():
		return State.FAILURE

	var live_prey: Array[Node2D] = []
	for n in candidates:
		if n is Creature:
			live_prey.append(n)
	if not live_prey.is_empty():
		var closest_prey = Node2DUtils.get_closest(creature.global_position, live_prey)
		creature.blackboard.set_value(Blackboard.KEY_TARGET_CREATURE, closest_prey)
		return State.SUCCESS

	var closest_food = Node2DUtils.get_closest(creature.global_position, candidates)
	creature.blackboard.set_value(Blackboard.KEY_TARGET_OBJECT, closest_food)

	return State.SUCCESS


## Same logic as EatGoal: when hungry, any food; when not hungry, only food with taming value.
func _get_food_candidates(creature: Creature, valid_foods: Array[Node2D]) -> Array[Node2D]:
	var hunger = creature.needs_component.get_need_value_or_null(NeedIds.HUNGER)
	if hunger != null and hunger <= 80:
		return valid_foods

	# Not hungry — we're only eating for taming, so only consider food with taming value
	if creature.creature_data != null and TamingNeed.get_taming_value_threshold(creature.creature_data) > 0:
		var taming_foods: Array[Node2D] = []
		for f in valid_foods:
			if f is WorldObject and TamableTrait.world_object_is_taming_target(creature, f as WorldObject):
				taming_foods.append(f)
		return taming_foods

	return []
