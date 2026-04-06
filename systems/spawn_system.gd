class_name SpawnSystem
extends Node

const SPAWN_INTERVAL: float = 10.0
var _stagger: ChunkStagger = ChunkStagger.new(SPAWN_INTERVAL)

func _physics_process(delta: float) -> void:
	var result: Dictionary = _stagger.update(delta)
	var chunks_to_update: Array[Vector2i] = result["chunks"]

	for coords in chunks_to_update:
		var chunk: Chunk = ChunkManager.loaded_chunks.get(coords, null)
		if chunk == null:
			continue

		if ConfigManager.config.spawn_world_objects:
			spawn_world_objects(chunk)


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
