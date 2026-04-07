extends Node

const CHUNK_UPDATE_INTERVAL: float = 0.5
var _chunk_stagger: ChunkStagger = ChunkStagger.new(CHUNK_UPDATE_INTERVAL)

var creature_scene := preload("res://features/creatures/creature.tscn")

var _biome_profiles_by_biome: Dictionary = {}

func _ready() -> void:
	_biome_profiles_by_biome.clear()
	for profile in ConfigManager.config.biome_creature_spawn_profiles:
		if profile == null:
			continue
		_biome_profiles_by_biome[profile.biome] = profile

func clear_all_entities() -> void:
	pass


func _on_chunk_unloaded(_chunk: Vector2i, _chunk_node: Chunk) -> void:
	pass


func _on_world_reset() -> void:
	clear_all_entities()

func spawn_creatures(chunk: Chunk, chunk_position: Vector2i) -> void:

	if ConfigManager.config.max_creatures_per_chunk <= 0:
		return

	var creatures_container: Node2D = chunk.get_creatures_container()
	if creatures_container != null and creatures_container.get_child_count() > 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y)

	var entity_count := rng.randi_range(1, ConfigManager.config.max_creatures_per_chunk)

	for i in range(entity_count):
		var local_x := rng.randi_range(0, Chunk.CHUNK_SIZE - 1)
		var local_y := rng.randi_range(0, Chunk.CHUNK_SIZE - 1)
		var world_x: int = chunk_position.x * Chunk.CHUNK_SIZE + local_x
		var world_y: int = chunk_position.y * Chunk.CHUNK_SIZE + local_y
		var tile_type := chunk.get_tile_type(local_x, local_y)
		var biome := chunk.get_biome(local_x, local_y)

		var biome_profile: Resource = _biome_profiles_by_biome.get(biome, null)

		var candidate_creatures: Array[CreatureData] = []
		var weights: Array[float] = []

		for creature_data in ConfigManager.config.allowed_creatures:
			if !creature_data.biomes.has(biome):
				continue
			if creature_data.excluded_tile_types.has(tile_type):
				continue

			# If a biome profile exists, it is the only source of weights.
			# Missing creatures in the profile get weight 0 (i.e., won't spawn).
			if biome_profile == null:
				candidate_creatures.append(creature_data)
				weights.append(1.0)
			else:
				var weights_map_any = biome_profile.get("creature_weights")
				var weights_map: Dictionary = {}
				if weights_map_any != null:
					weights_map = weights_map_any
				var w_val = weights_map.get(creature_data)
				var w: float = 0.0
				if w_val != null:
					w = float(w_val)
				if w > 0.0:
					candidate_creatures.append(creature_data)
					weights.append(w)

		if candidate_creatures.is_empty() or weights.is_empty():
			continue

		var picked_index := rng.rand_weighted(weights)
		var creature_data: CreatureData = candidate_creatures[picked_index]
		var pos := Vector2(
			world_x * Chunk.TILE_SIZE,
			world_y * Chunk.TILE_SIZE
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

func get_creature_count_in_chunk_by_id(chunk: Chunk, creature_id: StringName) -> int:
	var creatures_container: Node2D = chunk.get_creatures_container()
	if creatures_container == null:
		return 0
	var count := 0
	for entity in creatures_container.get_children():
		if !is_instance_valid(entity):
			continue
		if entity is not Creature:
			continue
		if (entity as Creature).creature_data.id == creature_id:
			count += 1
	return count


func get_creature_count_in_chunk(chunk_coords: Vector2i, creature_data: CreatureData) -> int:
	var chunk: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk == null:
		return 0
	return get_creature_count_in_chunk_by_id(chunk, creature_data.id)


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

func get_nearby_entities(origin: Vector2, radius: float) -> Array[Creature]:
	var results: Array[Creature] = []
	var radius_sq := radius * radius

	for key in ChunkUtils.get_chunk_coords_intersecting_circle(origin, radius):
		var chunk: Chunk = ChunkManager.get_loaded_chunk(key)
		if chunk == null:
			continue
		var creatures_container: Node2D = chunk.get_creatures_container()
		if creatures_container == null:
			continue

		for monster in creatures_container.get_children():
			if !is_instance_valid(monster) or not (monster is Creature):
				continue

			var dist_sq := origin.distance_squared_to(monster.global_position)

			if dist_sq <= radius_sq:
				results.append(monster as Creature)

	return results
