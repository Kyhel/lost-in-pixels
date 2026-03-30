class_name VegetationGenerator

var world_seed: int
var salt: int

func _init(p_seed: int) -> void:
	world_seed = p_seed

func generate_for_chunk(
	chunk_position: Vector2i,
	_chunk: Chunk,
) -> void:

	var max_vegetation: int = get_max_vegetation_for_chunk(_chunk)
	if max_vegetation <= 0:
		return

	var candidates: Array[Vector2i] = []
	for x in range(ChunkManager.CHUNK_SIZE):
		for y in range(ChunkManager.CHUNK_SIZE):
			var wx: int = chunk_position.x * ChunkManager.CHUNK_SIZE + x
			var wy: int = chunk_position.y * ChunkManager.CHUNK_SIZE + y
			if should_spawn_vegetation(wx, wy, x, y, _chunk):
				candidates.append(Vector2i(wx, wy))

	if candidates.is_empty():
		return

	_shuffle_vec2i_with_rng(candidates, get_rng(chunk_position))

	var picked: Array[Vector2i] = filter_candidates(candidates, max_vegetation)
	for tile: Vector2i in picked:
		spawn_vegetation(tile)

func spawn_vegetation(_world_tile: Vector2i) -> void:
	pass


func filter_candidates(candidates: Array[Vector2i], _max_vegetation: int) -> Array[Vector2i]:
	return candidates

func _conflicts_with_picked(tile: Vector2i, picked: Array[Vector2i], min_spacing: int) -> bool:
	for p: Vector2i in picked:
		if _chebyshev_tile(tile, p) < min_spacing:
			return true
	return false


func _chebyshev_tile(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))


func get_rng(chunk_position: Vector2i) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y) ^ salt
	return rng


func get_max_vegetation_for_chunk(_chunk: Chunk) -> int:
	return 0


func should_spawn_vegetation(_wx: int, _wy: int, _local_x: int, _local_y: int, _chunk: Chunk) -> bool:
	return false


func _shuffle_vec2i_with_rng(arr: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
