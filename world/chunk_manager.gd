extends Node2D

const TILE_SIZE = 16
const CHUNK_SIZE = 32

const LOAD_RADIUS = 1  # nombre de chunks à charger autour du joueur
const UNLOAD_RADIUS = 2 # au delà de ce rayon, les chunks sont déchargés

var loaded_chunks = {}

var chunk_scene = preload("res://world/chunk.tscn")
var generator = preload("res://world/world_generator.gd").new()
var fog_memory = {}

func get_chunk_key(x,y):
	return str(x) + "_" + str(y)

func load_chunk(chunk_x, chunk_y):

	var key = str(chunk_x) + "_" + str(chunk_y)

	if loaded_chunks.has(key):
		return

	print("loading chunk ", key)

	var chunk = chunk_scene.instantiate()

	add_child(chunk)

	chunk.position = Vector2(
		chunk_x * CHUNK_SIZE * TILE_SIZE,
		chunk_y * CHUNK_SIZE * TILE_SIZE
	)

	loaded_chunks[key] = chunk

	chunk.init_fog(fog_memory.get(key, null))

	generate_chunk(chunk_x, chunk_y, chunk)

func generate_chunk(chunk_x, chunk_y, chunk):

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):

			var world_x = chunk_x * CHUNK_SIZE + x
			var world_y = chunk_y * CHUNK_SIZE + y

			var tile = generator.get_tile(world_x, world_y)

			chunk.set_tile(x,y,tile)

func update_chunks(player_pos):

	var chunk_x = floor(player_pos.x / (CHUNK_SIZE * TILE_SIZE))
	var chunk_y = floor(player_pos.y / (CHUNK_SIZE * TILE_SIZE))

	for x in range(chunk_x-LOAD_RADIUS, chunk_x+LOAD_RADIUS+1):
		for y in range(chunk_y-LOAD_RADIUS, chunk_y+LOAD_RADIUS+1):
			load_chunk(x,y)

	unload_far_chunks(player_pos)

func unload_far_chunks(player_pos:Vector2):
	var player_chunk_x = floor(player_pos.x / (CHUNK_SIZE*TILE_SIZE))
	var player_chunk_y = floor(player_pos.y / (CHUNK_SIZE*TILE_SIZE))

	for key in loaded_chunks.keys():
		var parts = key.split("_")
		var chunk_x = int(parts[0])
		var chunk_y = int(parts[1])

		var dx = abs(chunk_x - player_chunk_x)
		var dy = abs(chunk_y - player_chunk_y)

		if dx > UNLOAD_RADIUS or dy > UNLOAD_RADIUS:
			var chunk = loaded_chunks[key]
			fog_memory[key] = chunk.fog_grid
			chunk.queue_free()  # supprime du tree
			loaded_chunks.erase(key)

func reveal_around_player(player_pos):

	var tile_pos = Vector2i(
		floor(player_pos.x / TILE_SIZE),
		floor(player_pos.y / TILE_SIZE)
	)

	var radius = 6

	for x in range(-radius,radius+1):
		for y in range(-radius,radius+1):

			if x*x + y*y <= radius*radius:

				var world_x = tile_pos.x + x
				var world_y = tile_pos.y + y

				reveal_tile(world_x,world_y)

func reveal_tile(world_x, world_y):

	var chunk_x = int(floor(world_x / float(CHUNK_SIZE)))
	var chunk_y = int(floor(world_y / float(CHUNK_SIZE)))

	var key = str(chunk_x) + "_" + str(chunk_y)

	if !loaded_chunks.has(key):
		return

	var chunk = loaded_chunks[key]

	var local_x = posmod(world_x, CHUNK_SIZE)
	var local_y = posmod(world_y, CHUNK_SIZE)

	chunk.reveal(local_x,local_y)
