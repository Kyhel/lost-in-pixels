extends Node

const CHUNK_UPDATE_INTERVAL: float = 0.5
var _chunk_stagger: ChunkStagger = ChunkStagger.new(CHUNK_UPDATE_INTERVAL)

var creature_scene := preload("res://features/creatures/creature.tscn")

var creature_spawn_probability_scores := []

func _ready() -> void:
	for creature_spawn_data in ConfigManager.config.allowed_creatures:
		creature_spawn_probability_scores.append([
			creature_spawn_data,
			ConfigManager.config.allowed_creatures[creature_spawn_data]
			])

func clear_all_entities() -> void:
	pass


func _on_chunk_unloaded(_chunk: Vector2i, _chunk_node: Chunk) -> void:
	pass


func _on_world_reset(_clear_fog_memory: bool) -> void:
	clear_all_entities()

func spawn_entities(chunk: Chunk, chunk_position: Vector2i) -> void:

	if ConfigManager.config.max_creatures_per_chunk <= 0:
		return

	var creatures_container: Node2D = chunk.get_creatures_container()
	if creatures_container != null and creatures_container.get_child_count() > 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y)

	var entity_count := rng.randi_range(1, ConfigManager.config.max_creatures_per_chunk)

	for i in range(entity_count):
		var local_x := rng.randi_range(0, ChunkManager.CHUNK_SIZE - 1)
		var local_y := rng.randi_range(0, ChunkManager.CHUNK_SIZE - 1)
		var world_x: int = chunk_position.x * ChunkManager.CHUNK_SIZE + local_x
		var world_y: int = chunk_position.y * ChunkManager.CHUNK_SIZE + local_y
		var tile_type := chunk.get_tile_type(local_x, local_y)
		var biome: WorldGenerator.Biome = chunk.get_biome(local_x, local_y)

		var valid_creatures := creature_spawn_probability_scores.filter(func(entry):
			var data: CreatureData = entry[0]
			return data.biomes.has(biome) and !data.excluded_tile_types.has(tile_type)
		).filter(func(entry):
			return ConfigManager.config.allowed_creatures.has(entry[0])
		)

		if valid_creatures.is_empty():
			continue

		var picked_index := rng.rand_weighted(valid_creatures.map(func(creature_spawn_probability): return creature_spawn_probability[1]))
		var creature_data: CreatureData = valid_creatures[picked_index][0]
		var pos := Vector2(
			world_x * ChunkManager.TILE_SIZE,
			world_y * ChunkManager.TILE_SIZE
		)
		spawn_creature_at(chunk_position, creature_data, pos)

func move_monster(monster: Creature, _old_chunk: Vector2i, new_chunk: Vector2i):
	var target_chunk: Chunk = ChunkManager.get_loaded_chunk(new_chunk)
	var target_container: Node2D = null
	if target_chunk != null:
		target_container = target_chunk.get_creatures_container()
	if target_container == null:
		if is_instance_valid(monster):
			monster.queue_free()
		return

	var world_pos: Vector2 = monster.global_position
	if monster.get_parent() != target_container:
		monster.reparent(target_container)
	monster.global_position = world_pos

func update_entity_chunks(delta: float) -> void:
	var result: Dictionary = _chunk_stagger.update(delta)
	var chunks_to_check: Array[Vector2i] = result["chunks"]

	for coords in chunks_to_check:
		var chunk: Chunk = ChunkManager.get_loaded_chunk(coords)
		if chunk == null:
			continue
		var creatures_container: Node2D = chunk.get_creatures_container()
		if creatures_container == null:
			continue

		var monsters: Array = creatures_container.get_children().duplicate()
		for monster_node in monsters:
			var monster: Creature = monster_node as Creature
			if monster == null:
				continue
			if !is_instance_valid(monster):
				continue

			var new_chunk: Vector2i = ChunkManager.world_pos_to_chunk_coords(monster.global_position)
			if new_chunk != coords:
				move_monster(monster, coords, new_chunk)

func update_entity_visibility(player_pos:Vector2):
	for chunk_node: Node in ChunkManager.loaded_chunks.values():
		if not is_instance_valid(chunk_node) or not chunk_node is Chunk:
			continue
		var chunk: Chunk = chunk_node as Chunk
		var creatures_container: Node2D = chunk.get_creatures_container()
		if creatures_container == null:
			continue
		for monster_node in creatures_container.get_children():
			var monster: Creature = monster_node as Creature
			if monster == null or !is_instance_valid(monster):
				continue

			monster.set_visible(is_monster_visible(monster.global_position, player_pos))

func is_monster_visible(world_pos:Vector2, player_pos:Vector2) -> bool:

	var dx = abs(world_pos.x - player_pos.x)
	var dy = abs(world_pos.y - player_pos.y)

	var distance_sq = dx*dx + dy*dy
	var radius_px = ChunkManager.MONSTER_VISION_RADIUS * ChunkManager.TILE_SIZE

	return distance_sq < radius_px * radius_px


func get_creature_count_in_chunk(chunk_coords: Vector2i, creature_data: CreatureData) -> int:
	var chunk: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk == null:
		return 0
	var creatures_container: Node2D = chunk.get_creatures_container()
	if creatures_container == null:
		return 0
	var count := 0
	for entity in creatures_container.get_children():
		if is_instance_valid(entity) and entity.get("creature_data") == creature_data:
			count += 1
	return count

func spawn_creature_at(chunk_coords: Vector2i, creature_data: CreatureData, world_pos: Vector2) -> void:
	var chunk: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk == null:
		return
	var target_container: Node2D = chunk.get_creatures_container()
	if target_container == null:
		return

	var creature = creature_scene.instantiate()
	creature.creature_data = creature_data
	creature.global_position = world_pos
	creature.virtual_rotation = randf() * TAU
	target_container.add_child(creature)
	creature.global_position = world_pos

func get_nearby_entities(origin: Vector2, radius: float) -> Array:
	var results: Array = []
	var radius_sq := radius * radius

	# Determine the chunk the origin is in
	var origin_chunk: Vector2i = ChunkManager.world_pos_to_chunk_coords(origin)

	# Only look in the origin chunk and its immediate neighbors (3x3 area)
	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			var chunk: Chunk = ChunkManager.get_loaded_chunk(key)
			if chunk == null:
				continue
			var creatures_container: Node2D = chunk.get_creatures_container()
			if creatures_container == null:
				continue

			# Iterate safely and skip any invalid (already freed) instances.
			for monster in creatures_container.get_children():
				if !is_instance_valid(monster):
					continue

				var dx = monster.global_position.x - origin.x
				var dy = monster.global_position.y - origin.y
				var dist_sq = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(monster)

	return results
