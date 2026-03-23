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


func spawn_vegetation(_chunk: Vector2i, _world_tile: Vector2i) -> void:
	VegetationManager.spawn_water_lily(_chunk, _world_tile)


func _conflicts_with_existing_water_lilies(tile: Vector2i, tile_size: float) -> bool:
	var center := Vector2(
		float(tile.x) * tile_size + tile_size * 0.5,
		float(tile.y) * tile_size + tile_size * 0.5,
	)
	var search_r: float = float(MIN_LILY_TILE_SPACING) * tile_size
	for veg in VegetationManager.get_nearby_vegetation(center, search_r):
		if not veg.is_water_lily():
			continue
		var ox: int = int(floor(veg.global_position.x / tile_size))
		var oy: int = int(floor(veg.global_position.y / tile_size))
		if _chebyshev_tile(tile, Vector2i(ox, oy)) < MIN_LILY_TILE_SPACING:
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
			if ChunkManager.get_tile_type_at_world_tile(tx, ty) != WorldGenerator.TileType.WATER:
				return true
	return false
