class_name ForageSensor
extends Sensor

@export var scan_radius: float = 300.0

func update(creature: Creature) -> void:
	if creature.blackboard == null:
		return

	var hunger_need: HungerNeed = null
	if creature.needs_component != null:
		hunger_need = creature.needs_component.get_need(NeedIds.HUNGER) as HungerNeed

	var origin: Vector2 = creature.global_position
	var nearby_objects: Array = ObjectsManager.get_nearby_world_objects(origin, scan_radius)
	var foods: Array[Node2D] = []
	var fetchables: Array[WorldObject] = []
	var fetchable_ids := _get_fetchable_object_ids(creature)

	for node in nearby_objects:
		if not node is WorldObject:
			continue
		var world_object := node as WorldObject
		if world_object.object_data == null:
			continue
		if hunger_need != null and _can_eat(hunger_need, world_object.object_data):
			foods.append(world_object)
		if fetchable_ids.has(world_object.object_data.id):
			fetchables.append(world_object)

	if hunger_need != null:
		var nearby_entities = CreatureManager.get_nearby_entities(origin, scan_radius)
		for entity in nearby_entities:
			if not entity is Creature:
				continue
			if entity == creature:
				continue
			if entity.blackboard.get_value(Blackboard.KEY_TAMED, false):
				continue
			if not _can_eat_creature(hunger_need, entity.creature_data):
				continue
			foods.append(entity)

	creature.blackboard.set_value(Blackboard.KEY_FOOD, foods)
	creature.blackboard.set_value(Blackboard.KEY_FETCHABLES, fetchables)


func _get_fetchable_object_ids(creature: Creature) -> Dictionary:
	var result := {}
	if creature == null or creature.creature_data == null:
		return result
	for trait_res in creature.creature_data.traits:
		var fetcher_trait := trait_res as FetcherTrait
		if fetcher_trait == null:
			continue
		for object_data in fetcher_trait.fetchable_objects:
			if object_data != null:
				result[object_data.id] = true
	return result


func _can_eat(hunger_need: HungerNeed, object_data: ObjectData) -> bool:
	for edible in hunger_need.edible_objects:
		if edible != null and edible.id == object_data.id:
			return true
	return false


func _can_eat_creature(hunger_need: HungerNeed, prey_data: CreatureData) -> bool:
	if prey_data == null:
		return false
	for edible in hunger_need.edible_creatures:
		if edible != null and edible == prey_data:
			return true
	return false
