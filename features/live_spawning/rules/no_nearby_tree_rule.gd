extends SpawnRule
class_name NoNearbyTreeRule

@export var radius: int = 5

func can_spawn(world_pos: Vector2, _context: Dictionary) -> bool:
	return ChunkManager.get_nearby_trees(world_pos, radius * Chunk.TILE_SIZE).is_empty()
