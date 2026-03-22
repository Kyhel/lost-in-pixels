class_name TreeGenerator
extends RefCounted

## Tiles from tree center in each direction reserved (no other tree). 1 = 3x3, 2 = 5x5, etc.
const TREE_SPACING_RADIUS := 5
const TREE_2_SPACING_RADIUS := 3
## Within each spacing cell, the tree can spawn in a smaller inner square (center ± this). 0 = center only, 1 = 3x3, etc. Must be <= TREE_SPACING_RADIUS.
const TREE_INNER_RADIUS := 2

enum TreeType {
	TREE_1,
	TREE_2
}

## One tile per spacing cell is allowed to have a tree; this is the outer cell side length.
func _get_spacing_cell_size(biome: WorldGenerator.Biome) -> int:
	match biome:
		WorldGenerator.Biome.FOREST:
			return 2 * TREE_2_SPACING_RADIUS + 1
		_:
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
	chunk_position: Vector2i,
	_chunk: Chunk,
	chunk_size: int,
) -> void:

	for x:int in range(chunk_size):
		for y:int in range(chunk_size):
			
			var global_x:int = chunk_position.x * chunk_size + x
			var global_y:int = chunk_position.y * chunk_size + y

			# Local chunk indices (x, y); do not use get_tile_coords_in_chunk_from_world_pos here —
			# that helper expects pixel positions, while global_* are world tile coordinates.
			var biome := _chunk.get_biome(x, y)
			var tile_type := _chunk.get_tile_type(x, y)

			if should_spawn_tree(global_x, global_y, tile_type, biome):
				var tree_type = get_tree_type(biome)
				ObjectsManager.spawn_tree(chunk_position, Vector2i(global_x, global_y), tree_type)


func should_spawn_tree(x: int, y: int, tile_type: WorldGenerator.TileType, biome: WorldGenerator.Biome) -> bool:
	if !_tile_passes_tree_rules(x, y, tile_type, biome):
		return false
	# Only one tile per spacing cell may have a tree; this tile must be the chosen one (deterministic).
	return _is_spacing_winner(x, y, biome)


func get_tree_type(biome: WorldGenerator.Biome) -> TreeType:
	match biome:
		WorldGenerator.Biome.PLAINS:
			return TreeType.TREE_1
		WorldGenerator.Biome.FOREST:
			return TreeType.TREE_2
		_:
			return TreeType.TREE_1

## True if this tile passes water/biome/noise/random rules (no adjacent-tree check). Deterministic.
func _tile_passes_tree_rules(wx: int, wy: int, tile_type: WorldGenerator.TileType, biome: WorldGenerator.Biome) -> bool:
	if tile_type == WorldGenerator.TileType.WATER:
		return false
	if biome != WorldGenerator.Biome.FOREST and biome != WorldGenerator.Biome.PLAINS:
		return false
	if tree_noise.get_noise_2d(wx, wy) < 0.1:
		return false
	if _tile_random(wx, wy) < 0.2:
		return false
	return true


## True if (wx, wy) is the deterministically chosen tile in its spacing cell (inner region only).
## Outer cell enforces spacing; inner region gives deterministic randomness.
func _is_spacing_winner(wx: int, wy: int, biome: WorldGenerator.Biome) -> bool:
	var cell_size: int = _get_spacing_cell_size(biome)
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
