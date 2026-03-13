class_name TreeGenerator
extends RefCounted

var tree_noise := FastNoiseLite.new()
var world_seed : int

func _init(p_seed:int) -> void:
	world_seed = p_seed
	
	tree_noise.seed = p_seed + 92837
	tree_noise.frequency = 0.08
	tree_noise.fractal_octaves = 3
	tree_noise.fractal_gain = 0.5

func generate_trees_for_chunk(
	chunk_position:Vector2i,
	chunk_size:int,
	biome_generator:WorldGenerator,
	objects_manager:ObjectsManager
) -> void:

	for x:int in range(chunk_size):
		for y:int in range(chunk_size):
			
			var global_x:int = chunk_position.x * chunk_size + x
			var global_y:int = chunk_position.y * chunk_size + y
			
			if should_spawn_tree(global_x, global_y, biome_generator):
				objects_manager.spawn_tree(chunk_position, Vector2i(global_x, global_y))

func should_spawn_tree(
	x:int,
	y:int,
	biome_generator:WorldGenerator
) -> bool:
	
	var biome:WorldGenerator.Biome = biome_generator.get_biome(x, y)
	
	if biome != WorldGenerator.Biome.FOREST and biome != WorldGenerator.Biome.PLAINS:
		return false
	
	var n:float = tree_noise.get_noise_2d(x, y)
	
	if n < 0.55:
		return false
	
	if _tile_random(x, y) < 0.35:
		return false
	
	return true

func _tile_random(x:int, y:int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(x, y)) + world_seed
	return rng.randf()
