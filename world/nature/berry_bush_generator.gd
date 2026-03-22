class_name BerryBushGenerator
extends RefCounted

var bush_noise := FastNoiseLite.new()
var world_seed: int


func _init(p_seed: int) -> void:
	world_seed = p_seed
	bush_noise.seed = p_seed + 482917
	bush_noise.frequency = 0.012
	bush_noise.fractal_octaves = 2
	bush_noise.fractal_gain = 0.55


const MAX_BUSHES_PER_CHUNK := 2
const CHUNK_SHUFFLE_SALT := 0xBEE3


func generate_berry_bushes_for_chunk(
	chunk_position: Vector2i,
	_chunk: Chunk,
	chunk_size: int,
	biome_generator: WorldGenerator,
	tree_generator: TreeGenerator,
) -> void:
	var candidates: Array[Vector2i] = []
	for x in range(chunk_size):
		for y in range(chunk_size):
			var wx: int = chunk_position.x * chunk_size + x
			var wy: int = chunk_position.y * chunk_size + y
			if should_spawn_bush(wx, wy, biome_generator, tree_generator):
				candidates.append(Vector2i(wx, wy))

	if candidates.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y) ^ CHUNK_SHUFFLE_SALT
	candidates.shuffle()

	var n: int = mini(MAX_BUSHES_PER_CHUNK, candidates.size())
	for i in n:
		ObjectsManager.spawn_berry_bush(chunk_position, candidates[i])


func should_spawn_bush(
	wx: int,
	wy: int,
	biome_generator: WorldGenerator,
	tree_generator: TreeGenerator,
) -> bool:
	var tile_type: WorldGenerator.TileType = biome_generator.get_tile_type(wx, wy)
	var biome: WorldGenerator.Biome = biome_generator.get_biome(wx, wy)
	if tree_generator.should_spawn_tree(wx, wy, tile_type, biome):
		return false
	if tile_type == WorldGenerator.TileType.WATER:
		return false
	if biome != WorldGenerator.Biome.FOREST and biome != WorldGenerator.Biome.PLAINS:
		return false
	if bush_noise.get_noise_2d(wx, wy) < 0.12:
		return false
	if _tile_random(wx, wy) < 0.93:
		return false
	return true


func _tile_random(x: int, y: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(x, y)) + world_seed + 0xBEE2
	return rng.randf()
