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

# func can_spawn(world_pos: Vector2, context: Dictionary) -> bool:

# 	if item_type == null:
# 		return false

# 	if !context.has("density_maps"):
# 		return false

# 	var density_maps = context["density_maps"]

# 	if !density_maps.has(item_type):
# 		return false

# 	var density_maps_for_item = density_maps[item_type]

# 	if !density_maps_for_item.has(radius):
# 		return false

# 	var density_map = density_maps_for_item[radius]

# 	var tile_coords = ChunkManager.get_tile_coords_from_world_pos(world_pos)
# 	var tile_coords_in_chunk = ChunkManager.get_tile_coords_relative_to_chunk(tile_coords)

# 	if density_map[tile_coords_in_chunk.x * ChunkManager.CHUNK_SIZE + tile_coords_in_chunk.y] >= max_items:
# 		return false

# 	return true
