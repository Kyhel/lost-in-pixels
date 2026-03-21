class_name SpawnSystem
extends Node

const SPAWN_INTERVAL: float = 10.0
var _stagger: ChunkStagger = ChunkStagger.new(SPAWN_INTERVAL)

const RABBIT_MAX_PER_CHUNK = 3
const RABBIT_SPAWN_INTERVAL = 5.0
const RABBIT_MIN_CREATURE_DISTANCE = 2.0 * ChunkManager.TILE_SIZE
const RABBIT_SPAWN_TRY_COUNT = 5
## Tracks last time we spawned a rabbit in each chunk (for rate limiting).
var _rabbit_last_spawn_time: Dictionary = {}


func _is_small_spawnable_item(item: ItemData) -> bool:
	return item.id == &"flower_red_1" or item.id == &"carrot"


func _physics_process(delta: float) -> void:
	var result: Dictionary = _stagger.update(delta)
	var chunks_to_update: Array[Vector2i] = result["chunks"]

	for coords in chunks_to_update:
		var chunk: Chunk = ChunkManager.loaded_chunks.get(coords, null)
		if chunk == null:
			continue
		spawn_in_chunk(chunk)
		spawn_creatures(chunk)

	var removed: Array[Vector2i] = result["removed"]
	for coords in removed:
		_rabbit_last_spawn_time.erase(coords)

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
					var centered := world_pos + Vector2.ONE * ChunkManager.TILE_SIZE / 2.0
					if _is_small_spawnable_item(item) and ObjectsManager.is_small_item_spawn_blocked(centered, item):
						continue
					ObjectsManager.spawn_item_in_chunk(chunk.coords, item, centered)

func spawn_creatures(chunk: Chunk) -> void:

	if !DebugManager.debug_config.spawn_rabbits:
		return

	var rabbit_count: int = EntitiesManager.get_creature_count_in_chunk(chunk.coords, EntitiesManager.rabbit_data)
	if rabbit_count >= RABBIT_MAX_PER_CHUNK:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - _rabbit_last_spawn_time.get(chunk.coords, -999.0) < RABBIT_SPAWN_INTERVAL:
		return

	var plains_tiles: Array[Vector2i] = []
	for local_y in ChunkManager.CHUNK_SIZE:
		for local_x in ChunkManager.CHUNK_SIZE:
			var tile_type := chunk.get_tile_type(local_x, local_y)
			var biome := chunk.get_biome(local_x, local_y)
			if biome != WorldGenerator.Biome.PLAINS:
				continue
			if EntitiesManager.rabbit_data.excluded_tile_types.has(tile_type):
				continue
			plains_tiles.append(Vector2i(local_x, local_y))

	if plains_tiles.is_empty():
		return

	var plains_ratio := plains_tiles.size() / float(ChunkManager.CHUNK_AREA)
	if randf() > plains_ratio:
		return

	for try in RABBIT_SPAWN_TRY_COUNT:
		var idx := randi() % plains_tiles.size()
		var local := plains_tiles[idx]
		var world_tile_x: int = chunk.coords.x * ChunkManager.CHUNK_SIZE + local.x
		var world_tile_y: int = chunk.coords.y * ChunkManager.CHUNK_SIZE + local.y
		var world_pos := Vector2(
			world_tile_x * ChunkManager.TILE_SIZE,
			world_tile_y * ChunkManager.TILE_SIZE
		)
		var nearby: Array = EntitiesManager.get_nearby_entities(world_pos, RABBIT_MIN_CREATURE_DISTANCE)
		if nearby.is_empty():
			EntitiesManager.spawn_creature_at(chunk.coords, EntitiesManager.rabbit_data, world_pos)
			_rabbit_last_spawn_time[chunk.coords] = now
			return
