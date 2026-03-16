extends Node

var chunk_entities: Dictionary[Vector2i, Array] = {}

var creature_scene = preload("res://entities/creature.tscn")
var wandering_bird_data: CreatureData = preload("res://entities/wandering_bird.tres") as CreatureData
var big_wandering_data: CreatureData = preload("res://entities/big_wandering.tres") as CreatureData
var rabbit_data: CreatureData = preload("res://entities/passive/rabbit.tres") as CreatureData

var creature_data_list := [rabbit_data, wandering_bird_data]
# var creature_data_list := [wandering_bird_data, big_wandering_data, rabbit_data]

func on_chunk_unloaded(chunk: Vector2i):

	if !chunk_entities.has(chunk):
		return

	for entity in chunk_entities[chunk]:
		if is_instance_valid(entity):
			entity.queue_free()

	chunk_entities.erase(chunk)

func spawn_entities(chunk:Chunk, chunk_position:Vector2i):

	if chunk_entities.has(chunk_position):
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_position.x, chunk_position.y)

	var entities = []

	var entity_count = rng.randi_range(1, 5)

	for i in range(entity_count):
		var creature = creature_scene.instantiate()

		var local_x = rng.randi_range(0, ChunkManager.CHUNK_SIZE - 1)
		var local_y = rng.randi_range(0, ChunkManager.CHUNK_SIZE - 1)

		var world_x = chunk_position.x * ChunkManager.CHUNK_SIZE + local_x
		var world_y = chunk_position.y * ChunkManager.CHUNK_SIZE + local_y

		var tile_type = chunk.get_tile_type(local_x, local_y)
		var biome = ChunkManager.world_generator.get_biome(world_x, world_y)

		var valid_creatures = creature_data_list.filter(func(creature_data):
			return creature_data.biomes.has(biome) and !creature_data.excluded_tile_types.has(tile_type)
		)

		if valid_creatures.is_empty():
			continue

		creature.creature_data = valid_creatures.pick_random()

		var pos = Vector2(
			world_x * ChunkManager.TILE_SIZE,
			world_y * ChunkManager.TILE_SIZE
		)

		creature.global_position = pos

		add_child(creature)

		entities.append(creature)

	chunk_entities[chunk_position] = entities

func move_monster(monster, old_chunk, new_chunk):

	if old_chunk in chunk_entities:
		chunk_entities[old_chunk].erase(monster)

	if not chunk_entities.has(new_chunk):
		chunk_entities[new_chunk] = []

	chunk_entities[new_chunk].append(monster)

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
