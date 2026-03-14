extends Node

var chunks:Dictionary[Vector2i, Dictionary] = {}

func update_chunks() -> void:
	for chunk in ChunkManager.loaded_chunks.values():
		var start_time = Time.get_ticks_msec()
		spawn_in_chunk(chunk)
		var end_time = Time.get_ticks_msec()
		print("spawn_in_chunk ", chunk.coords, " took ", end_time - start_time, "ms")

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

				if randf() > 0.1:
					continue

				var can_spawn := true
				for rule in item.spawn_definition.spawn_rules:
					var rule_can_spawn = rule.can_spawn(world_pos, context)
					if !rule_can_spawn:
						can_spawn = false
						break

				if can_spawn:
					ObjectsManager.spawn_item_in_chunk(chunk.coords, item, world_pos)
