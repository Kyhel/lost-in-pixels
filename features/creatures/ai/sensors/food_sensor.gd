class_name FoodSensor
extends Sensor

## Scans the surroundings for food the creature can eat and stores found positions in the creature's blackboard under [constant BLACKBOARD_KEY_FOOD].
## Edible types are configured on [member CreatureData.edible_items] and [member CreatureData.edible_creatures].

@export var scan_radius: float = 300.0

func update(creature: Creature) -> void:

	if creature.blackboard == null:
		print("Blackboard is null")
		return

	var data: CreatureData = creature.creature_data
	if data == null:
		return

	var origin: Vector2 = creature.global_position
	var nearby: Array = ObjectsManager.get_nearby_items(origin, scan_radius)
	var foods: Array[Node2D] = []

	for node in nearby:
		if not node is WorldItem:
			continue
		var world_item: WorldItem = node
		if world_item.item_data == null:
			continue
		if not _can_eat(data, world_item.item_data):
			continue
		foods.append(world_item)

	var nearby_entities = CreatureManager.get_nearby_entities(creature.global_position, scan_radius)

	for entity in nearby_entities:
		if not entity is Creature:
			continue
		if entity == creature:
			continue
		if entity.blackboard.get_value(Blackboard.KEY_TAMED) == true:
			continue
		if not _can_eat_creature(data, entity.creature_data):
			continue
		foods.append(entity)

	creature.blackboard.set_value(Blackboard.KEY_FOOD, foods)

func _can_eat(data: CreatureData, item_data: ItemData) -> bool:
	for edible in data.edible_items:
		if edible != null and edible.id == item_data.id:
			return true
	return false

func _can_eat_creature(predator_data: CreatureData, prey_data: CreatureData) -> bool:
	if prey_data == null:
		return false
	for edible in predator_data.edible_creatures:
		if edible != null and edible == prey_data:
			return true
	return false
