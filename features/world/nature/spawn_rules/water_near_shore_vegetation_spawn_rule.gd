class_name WaterNearShoreVegetationSpawnRule
extends StaticVegetationSpawnRule

## Max Chebyshev distance (in tiles) within which a non-water tile must exist for spawn to be valid.
## Matches `WaterLilyGenerator._water_is_near_non_water` with `SHORE_DISTANCE` set to this value.
@export var max_shore_distance: int = 3


func is_valid(local_tile: Vector2i, chunk: Chunk) -> bool:
	var wx: int = chunk.coords.x * ChunkManager.CHUNK_SIZE + local_tile.x
	var wy: int = chunk.coords.y * ChunkManager.CHUNK_SIZE + local_tile.y
	return _water_is_near_non_water(wx, wy)


func _water_is_near_non_water(wx: int, wy: int) -> bool:
	var d: int = max_shore_distance
	for dx in range(-d, d + 1):
		for dy in range(-d, d + 1):
			var tx: int = wx + dx
			var ty: int = wy + dy
			var world_tile: Vector2i = Vector2i(tx, ty)
			var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
			var local: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
			var ch: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
			var tile_type: WorldGenerator.TileType = WorldGenerator.TileType.WATER
			if ch != null:
				tile_type = ch.get_tile_type(local.x, local.y)
			else:
				tile_type = ChunkManager.world_generator.get_tile_type(tx, ty)
			if tile_type != WorldGenerator.TileType.WATER:
				return true
	return false
