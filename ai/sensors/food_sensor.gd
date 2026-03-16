extends Sensor

## Scans the surroundings for food the creature can eat and stores found positions in the creature's blackboard under [constant BLACKBOARD_KEY_FOOD].

@export var edible_items: Array[Resource] = []  ## ItemData resources this creature can eat (assign in editor).
@export var scan_radius: float = 300.0

func update(creature: Creature) -> void:
	if creature.blackboard == null:
		print("Blackboard is null")
		return
	var origin: Vector2 = creature.global_position
	var nearby: Array = ObjectsManager.get_nearby_items(origin, scan_radius)
	var foods: Array[WorldItem] = []

	for node in nearby:
		if not node is WorldItem:
			continue
		var world_item: WorldItem = node
		if world_item.item_data == null:
			continue
		if not _can_eat(world_item.item_data):
			continue
		foods.append(world_item)

	creature.blackboard.set_value(Blackboard.KEY_FOOD, foods)


func _can_eat(item_data: ItemData) -> bool:
	for edible in edible_items:
		if edible is ItemData and edible.id == item_data.id:
			return true
	return false
