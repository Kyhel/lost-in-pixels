class_name FetchWorldObjectAction
extends BTNode

const FETCH_STAMINA_COST: float = 10.0


func tick(creature: Creature, _delta: float) -> State:
	if creature.is_holding_world_object():
		return State.SUCCESS

	var target := creature.blackboard.get_value(Blackboard.KEY_TARGET_OBJECT) as WorldObject
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
	var stamina_inst: NeedInstance = null
	var fetch_desire_inst: NeedInstance = null
	if creature.needs_component != null:
		stamina_inst = creature.needs_component.get_instance(NeedIds.STAMINA)
		fetch_desire_inst = creature.needs_component.get_instance(NeedIds.FETCH_DESIRE)
	if stamina_inst != null:
		stamina_inst.set_value(stamina_inst.current_value - FETCH_STAMINA_COST)
	if fetch_desire_inst != null:
		fetch_desire_inst.set_value(NeedInstance.MIN_VALUE)
	creature.blackboard.set_value(Blackboard.KEY_TARGET_OBJECT, null)
	return State.SUCCESS
