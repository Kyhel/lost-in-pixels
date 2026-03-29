class_name TileTypeVegetationSpawnRule
extends StaticVegetationSpawnRule

@export var allowed_tile_types: Array[WorldGenerator.TileType] = []


func is_valid(local_tile: Vector2i, chunk: Chunk) -> bool:
	if allowed_tile_types.is_empty():
		return false
	var t: WorldGenerator.TileType = chunk.get_tile_type(local_tile.x, local_tile.y)
	return t in allowed_tile_types
