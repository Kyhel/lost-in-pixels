class_name WaterLilyGenerator
extends VegetationGenerator


func _init(p_seed: int) -> void:
	super(p_seed)
	salt = 0xE1E70001

const SHORE_DISTANCE := 2
## Minimum Chebyshev distance (in tiles) between any two water lilies so they do not form tight clusters.
const MIN_LILY_TILE_SPACING := 4


func get_max_vegetation_for_chunk(_chunk: Chunk) -> int:
	var water_tiles: int = 0
	for x in range(ChunkManager.CHUNK_SIZE):
		for y in range(ChunkManager.CHUNK_SIZE):
			if _chunk.get_tile_type(x, y) == WorldGenerator.TileType.WATER:
				water_tiles += 1
	return water_tiles


func filter_candidates(candidates: Array[Vector2i], max_count: int) -> Array[Vector2i]:
	var picked: Array[Vector2i] = []
	var tile_size: float = float(ChunkManager.TILE_SIZE)
	for c: Vector2i in candidates:
		if picked.size() >= max_count:
			break
		if _conflicts_with_picked(c, picked, MIN_LILY_TILE_SPACING):
			continue
		if _conflicts_with_existing_water_lilies(c, tile_size):
			continue
		picked.append(c)
	return picked


func spawn_vegetation(_world_tile: Vector2i) -> void:
	VegetationManager.spawn_water_lily(_world_tile)


func _conflicts_with_existing_water_lilies(tile: Vector2i, tile_size: float) -> bool:
	var center: Vector2 = ChunkManager.world_tile_to_world_center(tile)
	var search_r: float = float(MIN_LILY_TILE_SPACING) * tile_size
	for veg in VegetationManager.get_nearby_vegetation(center, search_r):
		if not veg.is_water_lily():
			continue
		var other_tile: Vector2i = ChunkManager.world_pos_to_world_tile(veg.global_position)
		if _chebyshev_tile(tile, other_tile) < MIN_LILY_TILE_SPACING:
			return true
	return false


func should_spawn_vegetation(wx: int, wy: int, local_x: int, local_y: int, chunk: Chunk) -> bool:
	if chunk.get_tile_type(local_x, local_y) != WorldGenerator.TileType.WATER:
		return false
	if not _water_is_near_non_water(wx, wy):
		return false
	if VegetationManager.is_environment_tile_occupied(Vector2i(wx, wy)):
		return false
	return true


func _water_is_near_non_water(wx: int, wy: int) -> bool:
	for dx in range(-SHORE_DISTANCE, SHORE_DISTANCE + 1):
		for dy in range(-SHORE_DISTANCE, SHORE_DISTANCE + 1):
			var tx: int = wx + dx
			var ty: int = wy + dy
			var world_tile: Vector2i = Vector2i(tx, ty)
			var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
			var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
			var chunk := ChunkManager.get_loaded_chunk(chunk_coords)
			var tile_type := WorldGenerator.TileType.WATER
			if chunk != null:
				tile_type = chunk.get_tile_type(local_tile.x, local_tile.y)
			else:
				tile_type = ChunkManager.world_generator.get_tile_type(tx, ty)
			if tile_type != WorldGenerator.TileType.WATER:
				return true
	return false
