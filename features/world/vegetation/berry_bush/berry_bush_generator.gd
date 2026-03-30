class_name BerryBushGenerator
extends VegetationGenerator

var bush_noise := FastNoiseLite.new()

func _init(p_seed: int) -> void:
	super(p_seed)
	salt = 0xBEE3
	bush_noise.seed = p_seed + 482917
	bush_noise.frequency = 0.012
	bush_noise.fractal_octaves = 2
	bush_noise.fractal_gain = 0.55


const MAX_BUSHES_PER_CHUNK := 2
const MIN_BUSH_TILE_SPACING := 4


func spawn_vegetation(_world_tile: Vector2i) -> void:
	VegetationManager.spawn_berry_bush(_world_tile)


func get_max_vegetation_for_chunk(_chunk: Chunk) -> int:
	return MAX_BUSHES_PER_CHUNK

func filter_candidates(candidates: Array[Vector2i], max_count: int) -> Array[Vector2i]:
	var picked: Array[Vector2i] = []
	var tile_size: float = float(ChunkManager.TILE_SIZE)
	for c: Vector2i in candidates:
		if picked.size() >= max_count:
			break
		if _conflicts_with_picked(c, picked, MIN_BUSH_TILE_SPACING):
			continue
		if _conflicts_with_existing_berry_bushes(c, tile_size):
			continue
		picked.append(c)
	return picked
	

func _conflicts_with_existing_berry_bushes(tile: Vector2i, tile_size: float) -> bool:
	var center: Vector2 = ChunkManager.world_tile_to_world_center(tile)
	var search_r: float = float(MIN_BUSH_TILE_SPACING) * tile_size
	for veg in VegetationManager.get_nearby_vegetation(center, search_r):
		if veg == null or veg.is_water_lily():
			continue
		var other_tile: Vector2i = ChunkManager.world_pos_to_world_tile(veg.global_position)
		if _chebyshev_tile(tile, other_tile) < MIN_BUSH_TILE_SPACING:
			return true
	return false

func should_spawn_vegetation(
	wx: int,
	wy: int,
	local_x: int,
	local_y: int,
	chunk: Chunk
) -> bool:
	var tile_type: WorldGenerator.TileType = chunk.get_tile_type(local_x, local_y)
	var biome: WorldGenerator.Biome = chunk.get_biome(local_x, local_y)
	if VegetationManager.is_environment_tile_occupied(Vector2i(wx, wy)):
		return false
	if tile_type == WorldGenerator.TileType.WATER:
		return false
	if biome != WorldGenerator.Biome.FOREST and biome != WorldGenerator.Biome.PLAINS:
		return false
	if bush_noise.get_noise_2d(wx, wy) < 0.1:
		return false
	return true


func _tile_random(x: int, y: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(x, y)) + world_seed + 0xBEE2
	return rng.randf()
