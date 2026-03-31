class_name FetchWorldObjectAction
extends BTNode

func tick(creature: Creature, _delta: float) -> State:
	if creature.is_holding_world_object():
		return State.SUCCESS

	var target := creature.blackboard.get_value(Blackboard.KEY_TARGET_FETCHABLE) as WorldObject
	if target == null or not is_instance_valid(target):
		return State.FAILURE
	if target.object_data == null:
		return State.FAILURE
	if not Node2DUtils.is_within_interaction_range(creature, target):
		return State.FAILURE

	var fetched_data := FetchableBehavior.get_fetched_object_data(target.object_data)
	if fetched_data == null:
		return State.FAILURE

	target.destroy("fetched")
	var held_object := ObjectsManager.spawn_object_attached(creature.get_held_item_anchor(), fetched_data)
	if held_object == null:
		return State.FAILURE
	if not creature.hold_world_object(held_object):
		held_object.queue_free()
		return State.FAILURE
	creature.blackboard.set_value(Blackboard.KEY_TARGET_FETCHABLE, null)
	return State.SUCCESS
