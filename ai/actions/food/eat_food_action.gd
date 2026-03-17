class_name EatFoodAction
extends BTNode

const EATING_TIME = 2.0
var eating_timer: float = 0.0

func tick(creature: Creature, _delta: float) -> State:

	if creature.blackboard.get_value(Blackboard.KEY_STATE) == Blackboard.State.EATING:

		if eating_timer <= 0.0:
			reset()
			creature.blackboard.set_value(Blackboard.KEY_STATE, Blackboard.State.IDLE)
			return State.SUCCESS

		if eating_timer > 0.0:
			eating_timer -= _delta
		return State.RUNNING

	var target_food = creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD)

	if target_food == null:
		return State.FAILURE

	if not PushPriorityHelper.is_within_interaction_range(creature, target_food):
		return State.FAILURE

	if target_food is WorldItem:
		var world_item: WorldItem = target_food
		if world_item.item_data != null and world_item.item_data.taming_value > 0 and creature.creature_data.taming_value_threshold > 0:
			var taming = creature.blackboard.get_value(Blackboard.KEY_TAMING)
			if taming == null:
				taming = 0
			taming = int(taming) + world_item.item_data.taming_value
			creature.blackboard.set_value(Blackboard.KEY_TAMING, taming)
			if taming >= creature.creature_data.taming_value_threshold:
				creature.blackboard.set_value(Blackboard.KEY_TAMED, true)

	target_food.be_eaten(creature)

	eating_timer = EATING_TIME
	creature.blackboard.set_value(Blackboard.KEY_STATE, Blackboard.State.EATING)
	creature.blackboard.set_value(Blackboard.KEY_HUNGER, Blackboard.KEY_HUNGER_MAX)
	creature.movement.stop()
	return State.RUNNING


func reset():
	eating_timer = 0.0
	super.reset()
