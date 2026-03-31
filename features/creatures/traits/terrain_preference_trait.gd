class_name TerrainPreferenceTrait
extends CreatureTrait

@export var preferred_terrains: Array[Terrain.Type] = []
@export var max_distance: int = 0


func is_tile_valid(tile_coords: Vector2i) -> bool:
	if preferred_terrains.is_empty():
		return true
	if _is_preferred_tile(tile_coords.x, tile_coords.y):
		return true
	for distance in range(1, maxi(0, max_distance) + 1):
		var min_x := tile_coords.x - distance
		var max_x := tile_coords.x + distance
		var min_y := tile_coords.y - distance
		var max_y := tile_coords.y + distance

		for x in range(min_x, max_x + 1):
			if _is_preferred_tile(x, min_y) or _is_preferred_tile(x, max_y):
				return true
		for y in range(min_y + 1, max_y):
			if _is_preferred_tile(min_x, y) or _is_preferred_tile(max_x, y):
				return true
	return false


func _is_preferred_tile(tile_x: int, tile_y: int) -> bool:
	var tile_coords := Vector2i(tile_x, tile_y)
	var world_pos := ChunkManager.world_tile_to_world_center(tile_coords)
	var tile_type := ChunkManager.get_tile_type_at_world_pos(world_pos)
	return preferred_terrains.has(tile_type)
