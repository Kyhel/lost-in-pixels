class_name RabbitEatingFrenzyEvent
extends AreaEvent

@export var effect := EatingFrenzyEffect

func apply(world_position: Vector2) -> void:
	
	if effect == null:
		push_error("Can't apply, effect is null")
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
		if EatingFrenzyEffect.find_on(creature) != null:
			continue
		var effect_instance = effect.new()
		creature.add_creature_effect(effect_instance)
		effect_instance.apply(creature)
