class_name SpawnSystem
extends Node

var spawn_timer: float = 0.0
const SPAWN_INTERVAL = 10.0
## Tracks the last spawn cycle we ran for each chunk (so we only update once per interval).
var _chunk_last_cycle: Dictionary = {}

func _get_chunk_phase(coords: Vector2i) -> float:
	## Deterministic phase in [0, SPAWN_INTERVAL) so updates are spread over the interval.
	var h := (coords.x * 73856093) ^ (coords.y * 19349663)
	return absf(float(h % 10000)) / 10000.0 * SPAWN_INTERVAL

func _physics_process(delta: float) -> void:
	spawn_timer += delta
	# Keep spawn_timer in [0, SPAWN_INTERVAL) and shift cycle counts so logic is unchanged
	if spawn_timer >= SPAWN_INTERVAL:
		var cycles_elapsed: int = int(floorf(spawn_timer / SPAWN_INTERVAL))
		spawn_timer = fmod(spawn_timer, SPAWN_INTERVAL)
		for coords in _chunk_last_cycle.keys():
			_chunk_last_cycle[coords] -= float(cycles_elapsed)

	for chunk in ChunkManager.loaded_chunks.values():
		var coords: Vector2i = chunk.coords
		var phase: float = _get_chunk_phase(coords)
		var current_cycle: float = floorf((spawn_timer - phase) / SPAWN_INTERVAL)
		var last_cycle: float = _chunk_last_cycle.get(coords, -1.0)
		if current_cycle > last_cycle:
			_chunk_last_cycle[coords] = current_cycle
			spawn_in_chunk(chunk)
	# Drop entries for unloaded chunks to avoid unbounded growth
	var loaded_keys := ChunkManager.loaded_chunks.keys()
	var to_remove: Array[Vector2i] = []
	for coords in _chunk_last_cycle.keys():
		if coords not in loaded_keys:
			to_remove.append(coords)
	for coords in to_remove:
		_chunk_last_cycle.erase(coords)

func spawn_in_chunk(chunk: Chunk) -> void:

	var items: Array = ItemDatabase.get_items()

	var spawnable_items: Array = []
	for item in items:
		if item.spawn_definition != null:
			spawnable_items.append(item)

	var context: Dictionary = {}

	for local_y in ChunkManager.CHUNK_SIZE:
		for local_x in ChunkManager.CHUNK_SIZE:

			var world_tile_x: int = chunk.coords.x * ChunkManager.CHUNK_SIZE + local_x
			var world_tile_y: int = chunk.coords.y * ChunkManager.CHUNK_SIZE + local_y
			var world_pos: Vector2 = Vector2(
				world_tile_x * ChunkManager.TILE_SIZE,
				world_tile_y * ChunkManager.TILE_SIZE
			)
			var tile_type = chunk.get_tile_type(local_x, local_y)
			var biome = chunk.get_biome(local_x, local_y)

			for item in spawnable_items:

				if item.spawn_definition.excluded_tile_types.has(tile_type):
					continue

				if !item.spawn_definition.biomes.has(biome):
					continue

				if randf() > 0.01:
					continue

				var can_spawn := true
				for rule in item.spawn_definition.spawn_rules:
					var rule_can_spawn = rule.can_spawn(world_pos, context)
					if !rule_can_spawn:
						can_spawn = false
						break

				if can_spawn:
					ObjectsManager.spawn_item_in_chunk(chunk.coords, item, world_pos)
