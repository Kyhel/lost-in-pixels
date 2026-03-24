class_name TreeGenerator
extends RefCounted

## Tiles from tree center in each direction reserved (plains / type 1 spacing between grove trees).
const TREE_SPACING_RADIUS := 5
const TREE_2_SPACING_RADIUS := 3

## Min Chebyshev distance between type-1 trees in the same plains grove (matches old 11-wide cell intent).
const MIN_PLAINS_TREE_SPACING := 2 * TREE_SPACING_RADIUS + 1

## Macro-cell for plains groves; trees are placed in the inner box inset from cell edges by MIN_PLAINS_TREE_SPACING
## so adjacent cells never conflict (order-independent).
const PLAINS_GROVE_CELL_SIZE := 48
const MAX_TREES_PER_PLAINS_GROVE := 5
const PLAINS_GROVE_PROBABILITY := 0.22
const PLAINS_GROVE_RNG_SALT := 0x50A7E5
const FOREST_PRIORITY_SALT := 0x7E12E5

enum TreeType {
	TREE_1,
	TREE_2
}

var tree_noise := FastNoiseLite.new()
var world_seed: int
var world_generator: WorldGenerator

func _init(p_seed: int) -> void:
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

	for x: int in range(chunk_size):
		for y: int in range(chunk_size):
			var global_x: int = chunk_position.x * chunk_size + x
			var global_y: int = chunk_position.y * chunk_size + y
			var tile_type: WorldGenerator.TileType = _chunk.get_tile_type(x, y)

			if _should_spawn_forest_tree(global_x, global_y, x, y, chunk_size, _chunk, tile_type):
				VegetationManager.spawn_tree(chunk_position, Vector2i(global_x, global_y), TreeType.TREE_2)

	_spawn_plains_grove_trees_for_chunk(chunk_position, _chunk, chunk_size)


func get_tree_type(tile_type: WorldGenerator.TileType) -> TreeType:
	match tile_type:
		WorldGenerator.TileType.DARK_GRASS:
			return TreeType.TREE_2
		WorldGenerator.TileType.GRASS:
			return TreeType.TREE_1
		_:
			return TreeType.TREE_1


func _should_spawn_forest_tree(
	wx: int,
	wy: int,
	local_x: int,
	local_y: int,
	chunk_size: int,
	_chunk: Chunk,
	tile_type: WorldGenerator.TileType,
) -> bool:
	if tile_type != WorldGenerator.TileType.DARK_GRASS:
		return false
	if !_forest_base_eligible(wx, wy, tile_type):
		return false
	var my_priority: int = _forest_priority(wx, wy)
	var r: int = TREE_2_SPACING_RADIUS
	for dx: int in range(-r, r + 1):
		for dy: int in range(-r, r + 1):
			if dx == 0 and dy == 0:
				continue
			var nx: int = wx + dx
			var ny: int = wy + dy
			var n_tile: WorldGenerator.TileType = _get_tile_type_world(nx, ny, local_x + dx, local_y + dy, chunk_size, _chunk)
			if !_forest_base_eligible(nx, ny, n_tile):
				continue
			if _forest_priority(nx, ny) >= my_priority:
				return false
	return true


func _forest_base_eligible(wx: int, wy: int, tile_type: WorldGenerator.TileType) -> bool:
	if tile_type != WorldGenerator.TileType.DARK_GRASS:
		return false
	if tree_noise.get_noise_2d(wx, wy) < 0.05:
		return false
	if _tile_random(wx, wy, 0) < 0.12:
		return false
	return true


func _forest_priority(wx: int, wy: int) -> int:
	return int(hash(Vector2i(wx, wy)) ^ world_seed ^ FOREST_PRIORITY_SALT)


func _get_tile_type_world(
	wx: int,
	wy: int,
	local_x: int,
	local_y: int,
	chunk_size: int,
	_chunk: Chunk,
) -> WorldGenerator.TileType:
	if local_x >= 0 and local_x < chunk_size and local_y >= 0 and local_y < chunk_size:
		return _chunk.get_tile_type(local_x, local_y)
	return world_generator.get_tile_type(wx, wy)


func _spawn_plains_grove_trees_for_chunk(chunk_position: Vector2i, _chunk: Chunk, chunk_size: int) -> void:
	var s: int = PLAINS_GROVE_CELL_SIZE
	var wx0: int = chunk_position.x * chunk_size
	var wy0: int = chunk_position.y * chunk_size
	var wx1: int = wx0 + chunk_size - 1
	var wy1: int = wy0 + chunk_size - 1
	var min_cx: int = int(floor(wx0 / float(s)))
	var max_cx: int = int(floor(wx1 / float(s)))
	var min_cy: int = int(floor(wy0 / float(s)))
	var max_cy: int = int(floor(wy1 / float(s)))
	for mcx: int in range(min_cx, max_cx + 1):
		for mcy: int in range(min_cy, max_cy + 1):
			var positions: Array[Vector2i] = _plains_grove_tree_positions(mcx, mcy)
			for p: Vector2i in positions:
				if p.x < wx0 or p.x > wx1 or p.y < wy0 or p.y > wy1:
					continue
				var lx: int = p.x - wx0
				var ly: int = p.y - wy0
				if _chunk.get_tile_type(lx, ly) != WorldGenerator.TileType.GRASS:
					continue
				VegetationManager.spawn_tree(chunk_position, p, TreeType.TREE_1)


func _plains_grove_tree_positions(mcx: int, mcy: int) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	var s: int = PLAINS_GROVE_CELL_SIZE
	var inset: int = MIN_PLAINS_TREE_SPACING
	if s <= 2 * inset:
		return empty
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(Vector2i(mcx, mcy)) ^ world_seed ^ PLAINS_GROVE_RNG_SALT)
	if rng.randf() > PLAINS_GROVE_PROBABILITY:
		return empty
	var x0: int = mcx * s + inset
	var y0: int = mcy * s + inset
	var x1: int = mcx * s + s - 1 - inset
	var y1: int = mcy * s + s - 1 - inset
	var grass_tiles: Array[Vector2i] = []
	for gx: int in range(x0, x1 + 1):
		for gy: int in range(y0, y1 + 1):
			if world_generator.get_tile_type(gx, gy) == WorldGenerator.TileType.GRASS:
				grass_tiles.append(Vector2i(gx, gy))
	if grass_tiles.is_empty():
		return empty
	var n: int = rng.randi_range(1, MAX_TREES_PER_PLAINS_GROVE)
	var picked: Array[Vector2i] = []
	var spacing: int = MIN_PLAINS_TREE_SPACING
	var max_attempts: int = maxi(80, grass_tiles.size() * 4)
	for _attempt: int in range(max_attempts):
		if picked.size() >= n:
			break
		var cand: Vector2i = grass_tiles[rng.randi_range(0, grass_tiles.size() - 1)]
		if _conflicts_plains_spacing(cand, picked, spacing):
			continue
		picked.append(cand)
	if picked.is_empty():
		return empty
	return picked


func _conflicts_plains_spacing(cand: Vector2i, picked: Array[Vector2i], min_cheb: int) -> bool:
	for q: Vector2i in picked:
		if _chebyshev_tile(cand, q) < min_cheb:
			return true
	return false


func _chebyshev_tile(a: Vector2i, b: Vector2i) -> int:
	return maxi(abs(a.x - b.x), abs(a.y - b.y))


func _tile_random(x: int, y: int, extra_salt: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(Vector2i(x, y)) ^ world_seed ^ extra_salt)
	return rng.randf()
