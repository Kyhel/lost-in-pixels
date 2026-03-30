class_name FoodSensor
extends Sensor

## Scans the surroundings for food the creature can eat and stores found positions in the creature's blackboard under [constant BLACKBOARD_KEY_FOOD].
## Edible types are configured on [member HungerNeed.edible_objects] and [member HungerNeed.edible_creatures] (hunger need in [member CreatureData.needs]).

@export var scan_radius: float = 300.0

func update(creature: Creature) -> void:

	if creature.blackboard == null:
		print("Blackboard is null")
		return

	var hunger_need: HungerNeed = null
	if creature.needs_component != null:
		hunger_need = creature.needs_component.get_need(NeedIds.HUNGER) as HungerNeed
	if hunger_need == null:
		creature.blackboard.set_value(Blackboard.KEY_FOOD, [])
		return

	var origin: Vector2 = creature.global_position
	var nearby: Array = ObjectsManager.get_nearby_world_objects(origin, scan_radius)
	var foods: Array[Node2D] = []

	for node in nearby:
		if not node is WorldObject:
			continue
		var world_object: WorldObject = node
		if world_object.object_data == null:
			continue
		if not _can_eat(hunger_need, world_object.object_data):
			continue
		foods.append(world_object)

	var nearby_entities = CreatureManager.get_nearby_entities(creature.global_position, scan_radius)

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
