extends Node2D

const CHUNK_SIZE = ChunkManager.CHUNK_SIZE
const FOG_TILE = 0

var fog_grid = [] # tableau 2D CHUNK_SIZE x CHUNK_SIZE

var tile_types = []

@onready var tilemap = $Terrain
@onready var fog = $Fog

func _ready() -> void:
	tile_types.resize(CHUNK_SIZE);
	for x in range(CHUNK_SIZE):
		tile_types[x] = []
		tile_types[x].resize(CHUNK_SIZE);

func set_tile_type(x:int, y:int, type):
	tile_types[x][y] = type

func set_tile(x:int, y:int, tile:Vector2i):

	tilemap.set_cell(
		Vector2i(x,y),
		0,
		tile
	)

func init_fog(grid : Variant = null):
	# If a saved grid is provided, use it,
	# otherwise create a fully covered fog grid.
	if grid != null:
		fog_grid = grid
	else:
		fog_grid.resize(CHUNK_SIZE)
		for x in range(CHUNK_SIZE):
			fog_grid[x] = []
			for y in range(CHUNK_SIZE):
				fog_grid[x].append(true)  # true = covered, false = revealed
	# Apply fog tiles based on fog_grid
	for x in range(CHUNK_SIZE):

		for y in range(CHUNK_SIZE):

			if fog_grid[x][y]: # true = couvert, false = révélé

				fog.set_cell(
					Vector2i(x,y),
					0,
					Vector2i(FOG_TILE,0)
				)

func reveal(x:int,y:int):
	if fog_grid[x][y]:
		fog_grid[x][y] = false
	fog.erase_cell(Vector2i(x,y))

func is_tile_visible(local_x:int, local_y:int) -> bool:
	return !fog_grid[local_x][local_y]
