extends Node2D
class_name Chunk

const CHUNK_SIZE = ChunkManager.CHUNK_SIZE
const CHUNK_AREA = CHUNK_SIZE * CHUNK_SIZE
const FOG_TILE = 0

var fog_grid = [] # tableau 2D CHUNK_SIZE x CHUNK_SIZE

var tile_types: Array[WorldGenerator.TileType] = []
var biomes: Array[WorldGenerator.Biome] = []
var environment_tile_occupied: Dictionary = {}
var world_objects: Array[WorldObject] = []

var coords: Vector2i

## Staged generation: terrain is always completed before the chunk is registered in ChunkManager.loaded_chunks.
var vegetation_generated := false
var creatures_generated := false

@onready var tilemap : TileMapLayer = $Terrain
@onready var fog : TileMapLayer = $Fog
@onready var creatures_container: Node2D = $Creatures
@onready var objects_container: Node2D = $Objects
@onready var vegetation_container: Node2D = $Vegetation

func _ready() -> void:
	z_index = Constants.Z_INDEX_TERRAIN
	tile_types.resize(CHUNK_AREA);
	biomes.resize(CHUNK_AREA);

func set_biome(x:int, y:int, biome: WorldGenerator.Biome) -> void:
	biomes[x * CHUNK_SIZE + y] = biome

func get_biome(x:int, y:int) -> WorldGenerator.Biome:
	return biomes[x * CHUNK_SIZE + y]

func set_tile_type(x:int, y:int, type: WorldGenerator.TileType) -> void:
	tile_types[x * CHUNK_SIZE + y] = type

func get_tile_type(x:int, y:int) -> WorldGenerator.TileType:
	return tile_types[x * CHUNK_SIZE + y]

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


func get_creatures_container() -> Node2D:
	return creatures_container


func get_objects_container() -> Node2D:
	return objects_container


func get_vegetation_container() -> Node2D:
	return vegetation_container


func register_environment_tile(local_tile: Vector2i) -> void:
	environment_tile_occupied[local_tile] = true


func is_environment_tile_occupied(local_tile: Vector2i) -> bool:
	return environment_tile_occupied.has(local_tile)


func register_world_object(world_object: WorldObject) -> void:
	if world_object == null:
		return
	if world_objects.has(world_object):
		return
	world_objects.append(world_object)


func unregister_world_object(world_object: WorldObject) -> void:
	if world_object == null:
		return
	world_objects.erase(world_object)


func get_world_objects() -> Array[WorldObject]:
	return world_objects
