class_name TreeGenerator
extends RefCounted

## Tiles from tree center in each direction reserved (no other tree). 1 = 3x3, 2 = 5x5, etc.
const TREE_SPACING_RADIUS := 3
## Within each spacing cell, the tree can spawn in a smaller inner square (center ± this). 0 = center only, 1 = 3x3, etc. Must be <= TREE_SPACING_RADIUS.
const TREE_INNER_RADIUS := 2

## One tile per spacing cell is allowed to have a tree; this is the outer cell side length.
func _get_spacing_cell_size() -> int:
	return 2 * TREE_SPACING_RADIUS + 1

var tree_noise := FastNoiseLite.new()
var world_seed : int

func _init(p_seed:int) -> void:
	world_seed = p_seed
	
	tree_noise.seed = p_seed + 92837
	tree_noise.frequency = 0.004
	tree_noise.fractal_octaves = 3
	tree_noise.fractal_gain = 0.5

func generate_trees_for_chunk(
	chunk_position:Vector2i,
	_chunk:Chunk,
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

## True if this tile passes water/biome/noise/random rules (no adjacent-tree check). Deterministic.
func _tile_passes_tree_rules(wx: int, wy: int, biome_generator: WorldGenerator) -> bool:
	var tile_type: WorldGenerator.TileType = biome_generator.get_tile_type(wx, wy)
	if tile_type == WorldGenerator.TileType.WATER:
		return false
	var biome: WorldGenerator.Biome = biome_generator.get_biome(wx, wy)
	if biome != WorldGenerator.Biome.FOREST and biome != WorldGenerator.Biome.PLAINS:
		return false
	if tree_noise.get_noise_2d(wx, wy) < 0.3:
		return false
	if _tile_random(wx, wy) < 0.2:
		return false
	return true

func should_spawn_tree(x: int, y: int, biome_generator: WorldGenerator) -> bool:
	if !_tile_passes_tree_rules(x, y, biome_generator):
		return false
	# Only one tile per spacing cell may have a tree; this tile must be the chosen one (deterministic).
	return _is_spacing_winner(x, y)

## True if (wx, wy) is the deterministically chosen tile in its spacing cell (inner region only).
## Outer cell enforces spacing; inner region gives deterministic randomness.
func _is_spacing_winner(wx: int, wy: int) -> bool:
	var cell_size: int = _get_spacing_cell_size()
	var cell_x: int = int(floor(wx / float(cell_size)))
	var cell_y: int = int(floor(wy / float(cell_size)))
	var local_x: int = posmod(wx, cell_size)
	var local_y: int = posmod(wy, cell_size)
	# Inner region: center ± TREE_INNER_RADIUS (e.g. 1 → 3x3 around center)
	var inner_size: int = 2 * TREE_INNER_RADIUS + 1
	var inner_min: int = TREE_SPACING_RADIUS - TREE_INNER_RADIUS
	if local_x < inner_min or local_x > inner_min + inner_size - 1:
		return false
	if local_y < inner_min or local_y > inner_min + inner_size - 1:
		return false
	# One winner per cell: pick a tile in the inner region deterministically
	var cell_seed: int = hash(Vector2i(cell_x, cell_y)) + world_seed
	var winner_index: int = posmod(cell_seed, inner_size * inner_size)
	var winner_offset_x: int = winner_index % inner_size
	var winner_offset_y: int = floori(winner_index / float(inner_size)) % inner_size
	return (local_x == inner_min + winner_offset_x) and (local_y == inner_min + winner_offset_y)

func _tile_random(x: int, y: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(x, y)) + world_seed
	return rng.randf()
