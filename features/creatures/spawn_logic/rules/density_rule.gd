class_name DensityRule
extends SpawnRule

@export var max_items: int = 2
@export var min_items: int = 1
@export var radius: int = 10
@export var item_type: StringName

func can_spawn(world_pos: Vector2, _context: Dictionary) -> bool:

	if item_type == null:
		return true

	var radius_px: float = radius * ChunkManager.TILE_SIZE
	var nearby: Array = ObjectsManager.get_nearby_items(world_pos, radius_px)

	var count: int = 0
	for item in nearby:
		if is_instance_valid(item) and item.item_data.id == item_type:
			count += 1

	# After spawning we'd have count+1; it must be in [min_items, max_items]
	return count >= min_items - 1 and count <= max_items - 1
