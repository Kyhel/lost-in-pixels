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

	if target_food.global_position.distance_to(creature.global_position) > 10:
		return State.FAILURE

	# for item in ObjectsManager.get_nearby_items(creature.global_position, 10):
	target_food.on_picked_up(self)
	eating_timer = EATING_TIME
	creature.blackboard.set_value(Blackboard.KEY_STATE, Blackboard.State.EATING)
	creature.blackboard.set_value(Blackboard.KEY_HUNGER, Blackboard.KEY_HUNGER_MAX)
	creature.movement.stop()
	return State.RUNNING


func reset():
	eating_timer = 0.0
	super.reset()
