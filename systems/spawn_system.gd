class_name SpawnSystem
extends Node

const SPAWN_INTERVAL: float = 10.0
var _stagger: ChunkStagger = ChunkStagger.new(SPAWN_INTERVAL)

const RABBIT_MAX_PER_CHUNK = 2
const RABBIT_SPAWN_INTERVAL = 5.0
const RABBIT_MIN_CREATURE_DISTANCE = 2.0 * ChunkManager.TILE_SIZE
const RABBIT_SPAWN_TRY_COUNT = 5
## Tracks last time we spawned a rabbit in each chunk (for rate limiting).
var _rabbit_last_spawn_time: Dictionary = {}


func _physics_process(delta: float) -> void:
	var result: Dictionary = _stagger.update(delta)
	var chunks_to_update: Array[Vector2i] = result["chunks"]

	for coords in chunks_to_update:
		var chunk: Chunk = ChunkManager.loaded_chunks.get(coords, null)
		if chunk == null:
			continue

		if ConfigManager.config.spawn_world_objects:
			spawn_world_objects(chunk)
			
		if ConfigManager.config.spawn_rabbits:
			spawn_rabbits(chunk)

	var removed: Array[Vector2i] = result["removed"]
	for coords in removed:
		_rabbit_last_spawn_time.erase(coords)

func _on_chunk_unloaded(chunk: Vector2i, _chunk_node: Chunk) -> void:
	_rabbit_last_spawn_time.erase(chunk)


func _on_world_reset() -> void:
	_rabbit_last_spawn_time.clear()

func spawn_world_objects(chunk: Chunk) -> void:

	var defs_dict := ConfigManager.config.realtime_spawn_definitions
	var spawnable_defs: Array[SpawnDefinition] = []
	for def in defs_dict:
		if not def is SpawnDefinition:
			continue
		var spawn_def: SpawnDefinition = def as SpawnDefinition
		if not defs_dict[def]:
			continue
		if spawn_def.object_data == null:
			continue
		spawnable_defs.append(spawn_def)

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

			for spawn_def in spawnable_defs:
				var object_data: ObjectData = spawn_def.object_data

				if spawn_def.excluded_tile_types.has(tile_type):
					continue

				if !spawn_def.biomes.has(biome):
					continue

				if randf() > 0.01:
					continue

				var can_spawn := true
				for rule in spawn_def.spawn_rules:
					var rule_can_spawn = rule.can_spawn(world_pos, context)
					if !rule_can_spawn:
						can_spawn = false
						break

				if can_spawn:
					var centered := world_pos + Vector2.ONE * ChunkManager.TILE_SIZE / 2.0
					if ObjectsManager.is_object_spawn_blocked(centered, object_data):
						continue
					ObjectsManager.spawn_object_in_chunk(chunk.coords, object_data, centered)

func spawn_rabbits(chunk: Chunk) -> void:

	# We don't want to spawn rabbits if the chunk doesn't have any creatures generated yet.
	if !chunk.creatures_generated:
		return

	if !ConfigManager.config.spawn_rabbits:
		return

	var rabbit_count: int = CreatureManager.get_creature_count_in_chunk_by_id(chunk, CreatureIds.RABBIT)
	if rabbit_count >= RABBIT_MAX_PER_CHUNK:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - _rabbit_last_spawn_time.get(chunk.coords, -999.0) < RABBIT_SPAWN_INTERVAL:
		return

	var rabbit_data := CreatureDatabase.get_creature_data(CreatureIds.RABBIT)

	var plains_tiles: Array[Vector2i] = []
	for local_y in ChunkManager.CHUNK_SIZE:
		for local_x in ChunkManager.CHUNK_SIZE:
			var tile_type := chunk.get_tile_type(local_x, local_y)
			var biome := chunk.get_biome(local_x, local_y)
			if biome != TerrainGenerator.Biome.PLAINS:
				continue
			if rabbit_data.excluded_tile_types.has(tile_type):
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
		var nearby: Array = CreatureManager.get_nearby_entities(world_pos, RABBIT_MIN_CREATURE_DISTANCE)
		if nearby.is_empty():
			CreatureManager.spawn_creature_at(chunk.coords, rabbit_data, world_pos)
			_rabbit_last_spawn_time[chunk.coords] = now
			return
