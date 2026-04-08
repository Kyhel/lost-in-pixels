class_name RabbitEatingFrenzyEvent
extends AreaEvent

@export var effects : Array[CreatureEffect] = []

func apply(world_position: Vector2) -> void:
	
	if effects.is_empty():
		push_error("Can't apply, effects are empty")
		return

	GameLog.log_message("A strange affliction has befallen the rabbits in the area ! They seem to be hungrier than usual.")
	
	var nearby: Array = CreatureManager.get_nearby_entities(world_position, radius)
	for node in nearby:
		if node == null or not node is Creature:
			continue
		var creature: Creature = node as Creature
		if creature.creature_data == null:
			continue
		if creature.creature_data.id != CreatureIds.RABBIT:
			continue
		CreatureEffectsUtils.add_effects(creature, effects)
		_setup_remove_effects_callback(creature)


func _setup_remove_effects_callback(creature: Creature) -> void:

	var _received_item_cb = func(_creature: Creature, item_id: StringName, target: Creature, callable: Callable) -> void:
		if _on_creature_received_item(_creature, item_id, target):
			if PlayerCreatureInteractionSystem.creature_received_item.is_connected(callable):
				PlayerCreatureInteractionSystem.creature_received_item.disconnect(callable)
	
	PlayerCreatureInteractionSystem.creature_received_item.connect(_received_item_cb.bind(creature, _received_item_cb))


func _on_creature_received_item(creature: Creature, item_id: StringName, target: Creature) -> bool:
	if creature != target:
		return false
	if item_id != ItemIds.NIGHT_FLOWER:
		return false
	if not is_instance_valid(creature):
		return false
	CreatureEffectsUtils.remove_effects(creature, effects)
	return true
