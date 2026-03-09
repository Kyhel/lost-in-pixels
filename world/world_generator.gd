extends Node

var noise = FastNoiseLite.new()

func _ready():
	noise.frequency = 0.03

func generate_chunk(chunk_x, chunk_y, chunk):

	for x in range(chunk.CHUNK_SIZE):
		for y in range(chunk.CHUNK_SIZE):

			var world_x = chunk_x * chunk.CHUNK_SIZE + x
			var world_y = chunk_y * chunk.CHUNK_SIZE + y

			var n = noise.get_noise_2d(world_x, world_y)

			if n > 0:
				chunk.set_tile(x, y, 1)
			else:
				chunk.set_tile(x, y, 0)

func get_tile(world_x, world_y):

	var n = noise.get_noise_2d(world_x, world_y)

	if n < -0.2:
		return 3 # eau
	elif n < 0.2:
		return 1 # sable
	else:
		return 2 # herbe
