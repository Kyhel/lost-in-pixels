extends Node

var chunk_entities: Dictionary[Vector2i, Array] = {}

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
	for chunk in chunk_entities.keys():
		for entity in chunk_entities[chunk]:
			if is_instance_valid(entity):
				entity.queue_free()
	chunk_entities.clear()


func _on_chunk_unloaded(chunk: Vector2i, _chunk_node: Chunk) -> void:

	if !chunk_entities.has(chunk):
		return

	for entity in chunk_entities[chunk]:
		if is_instance_valid(entity):
			entity.queue_free()

	chunk_entities.erase(chunk)

func spawn_entities(chunk: Chunk, chunk_position: Vector2i) -> void:

	if ConfigManager.config.max_creatures_per_chunk <= 0:
		return

	if chunk_entities.has(chunk_position):
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

func move_monster(monster: Creature, old_chunk: Vector2i, new_chunk: Vector2i):

	if old_chunk in chunk_entities:
		chunk_entities[old_chunk].erase(monster)

	if !chunk_entities.has(new_chunk):
		if is_instance_valid(monster):
			monster.queue_free()
		return

	chunk_entities[new_chunk].append(monster)

func update_entity_chunks(delta: float) -> void:
	var result: Dictionary = _chunk_stagger.update(delta)
	var chunks_to_check: Array[Vector2i] = result["chunks"]

	for coords in chunks_to_check:
		if !chunk_entities.has(coords):
			continue

		var monsters: Array = chunk_entities[coords].duplicate()
		for monster in monsters:
			if !is_instance_valid(monster):
				continue

			var new_chunk: Vector2i = ChunkManager.get_chunk_from_position(monster.global_position)
			if new_chunk != coords:
				move_monster(monster, coords, new_chunk)
				
		chunk_entities[coords] = ArrayUtils.cleanup_invalid_entries(chunk_entities[coords])

func update_entity_visibility(player_pos:Vector2):

	for key in chunk_entities.keys():

		for monster in chunk_entities[key]:

			if !is_instance_valid(monster):
				continue

			monster.set_visible(is_monster_visible(monster.global_position, player_pos))

func is_monster_visible(world_pos:Vector2, player_pos:Vector2) -> bool:

	var dx = abs(world_pos.x - player_pos.x)
	var dy = abs(world_pos.y - player_pos.y)

	var distance_sq = dx*dx + dy*dy
	var radius_px = ChunkManager.MONSTER_VISION_RADIUS * ChunkManager.TILE_SIZE

	return distance_sq < radius_px * radius_px


func get_creature_count_in_chunk(chunk_coords: Vector2i, creature_data: CreatureData) -> int:
	if !chunk_entities.has(chunk_coords):
		return 0
	var count := 0
	for entity in chunk_entities[chunk_coords]:
		if is_instance_valid(entity) and entity.get("creature_data") == creature_data:
			count += 1
	return count

func spawn_creature_at(chunk_coords: Vector2i, creature_data: CreatureData, world_pos: Vector2) -> void:
	var creature = creature_scene.instantiate()
	creature.creature_data = creature_data
	creature.global_position = world_pos
	add_child(creature)
	if !chunk_entities.has(chunk_coords):
		chunk_entities[chunk_coords] = []
	chunk_entities[chunk_coords].append(creature)

func get_nearby_entities(origin: Vector2, radius: float) -> Array:
	var results: Array = []
	var radius_sq := radius * radius

	# Determine the chunk the origin is in
	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	# Only look in the origin chunk and its immediate neighbors (3x3 area)
	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			if !chunk_entities.has(key):
				continue

			# Iterate safely and skip any invalid (already freed) instances.
			for monster in chunk_entities[key]:
				if !is_instance_valid(monster):
					continue

				var dx = monster.global_position.x - origin.x
				var dy = monster.global_position.y - origin.y
				var dist_sq = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(monster)

	return results
