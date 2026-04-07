class_name CreatureDensityRule
extends SpawnRule

@export var max_creatures: int = 2
@export var min_creatures: int = 1
## Search radius in **pixels** (world units).
@export var radius: float = 160.0
@export var creature_id: StringName

func can_spawn(world_pos: Vector2, _context: Dictionary) -> bool:
	if creature_id == null or creature_id == &"":
		return true

	var nearby: Array = CreatureManager.get_nearby_entities(world_pos, radius)

	var count: int = 0
	for entity in nearby:
		if !is_instance_valid(entity) or not (entity is Creature):
			continue
		var c: Creature = entity as Creature
		if c.creature_data != null and c.creature_data.id == creature_id:
			count += 1

	# After spawning we'd have count+1; it must be in [min_items, max_items]
	return count >= min_creatures - 1 and count <= max_creatures - 1
