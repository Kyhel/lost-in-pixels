class_name WaterLilyGenerator
extends RefCounted

var world_seed: int


func _init(p_seed: int) -> void:
	world_seed = p_seed


const SHORE_DISTANCE := 3
const CHUNK_SHUFFLE_SALT := 0xE1E70001
## Minimum Chebyshev distance (in tiles) between any two water lilies so they do not form tight clusters.
const MIN_LILY_TILE_SPACING := 4


func generate_water_lilies_for_chunk(
	chunk_position: Vector2i,
	_chunk: Chunk,
	chunk_size: int,
	biome_generator: WorldGenerator,
) -> void:
	var water_tiles: int = 0
	for x in range(chunk_size):
		for y in range(chunk_size):
			var wx: int = chunk_position.x * chunk_size + x
			var wy: int = chunk_position.y * chunk_size + y
			if biome_generator.get_tile_type(wx, wy) == WorldGenerator.TileType.WATER:
				water_tiles += 1

	var max_lilies: int = water_tiles / 60
	if max_lilies <= 0:
		return

	var candidates: Array[Vector2i] = []
	for x in range(chunk_size):
		for y in range(chunk_size):
			var wx: int = chunk_position.x * chunk_size + x
			var wy: int = chunk_position.y * chunk_size + y
			if should_spawn_water_lily(wx, wy, biome_generator):
				candidates.append(Vector2i(wx, wy))

	if candidates.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y) ^ CHUNK_SHUFFLE_SALT
	_shuffle_vec2i_with_rng(candidates, rng)

	var picked: Array[Vector2i] = _pick_spaced_candidates(candidates, max_lilies)
	for tile: Vector2i in picked:
		ObjectsManager.spawn_water_lily(chunk_position, tile)


func _shuffle_vec2i_with_rng(arr: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _pick_spaced_candidates(candidates: Array[Vector2i], max_count: int) -> Array[Vector2i]:
	var picked: Array[Vector2i] = []
	var tile_size: float = float(ChunkManager.TILE_SIZE)
	for c: Vector2i in candidates:
		if picked.size() >= max_count:
			break
		if _conflicts_with_picked(c, picked):
			continue
		if _conflicts_with_existing_water_lilies(c, tile_size):
			continue
		picked.append(c)
	return picked


func _conflicts_with_picked(tile: Vector2i, picked: Array[Vector2i]) -> bool:
	for p: Vector2i in picked:
		if _chebyshev_tile(tile, p) < MIN_LILY_TILE_SPACING:
			return true
	return false


func _conflicts_with_existing_water_lilies(tile: Vector2i, tile_size: float) -> bool:
	var center := Vector2(
		float(tile.x) * tile_size + tile_size * 0.5,
		float(tile.y) * tile_size + tile_size * 0.5,
	)
	var search_r: float = float(MIN_LILY_TILE_SPACING) * tile_size
	for veg in ObjectsManager.get_nearby_vegetation(center, search_r):
		if not veg.is_water_lily():
			continue
		var ox: int = int(floor(veg.global_position.x / tile_size))
		var oy: int = int(floor(veg.global_position.y / tile_size))
		if _chebyshev_tile(tile, Vector2i(ox, oy)) < MIN_LILY_TILE_SPACING:
			return true
	return false


func _chebyshev_tile(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))


func should_spawn_water_lily(wx: int, wy: int, biome_generator: WorldGenerator) -> bool:
	if biome_generator.get_tile_type(wx, wy) != WorldGenerator.TileType.WATER:
		return false
	if not _water_is_near_non_water(wx, wy, biome_generator):
		return false
	if ObjectsManager.is_environment_tile_occupied(Vector2i(wx, wy)):
		return false
	return true


func _water_is_near_non_water(wx: int, wy: int, biome_generator: WorldGenerator) -> bool:
	for dx in range(-SHORE_DISTANCE, SHORE_DISTANCE + 1):
		for dy in range(-SHORE_DISTANCE, SHORE_DISTANCE + 1):
			var tx: int = wx + dx
			var ty: int = wy + dy
			if biome_generator.get_tile_type(tx, ty) != WorldGenerator.TileType.WATER:
				return true
	return false
