class_name GiveHeldObjectToPlayerAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	var held := creature.get_held_world_object()
	if held == null or held.object_data == null:
		creature.clear_held_world_object(true)
		return State.FAILURE

	var item := PickableBehavior.get_pickup_item(held.object_data)
	if item == null:
		return State.FAILURE

	PlayerCreatureInteractionSystem.creature_give_item_to_player(creature, item.id, 1)
	creature.clear_held_world_object(true)
	creature.blackboard.set_value(Blackboard.KEY_TARGET_FETCHABLE, null)
	return State.SUCCESS
