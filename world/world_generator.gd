extends Node
class_name WorldGenerator

enum TileType {
	WATER,
	SAND,
	GRASS,
	DARK_GRASS
}

const TILE_DEFS = {
	TileType.WATER: {
		"atlas": Vector2i(3, 0),
		"walkable": false,
		"walk_speed": 0.0,
	},
	TileType.SAND: {
		"atlas": Vector2i(1, 0),
		"walkable": true,
		"walk_speed": 0.6,
	},
	TileType.GRASS: {
		"atlas": Vector2i(2, 0),
		"walkable": true,
		"walk_speed": 1.0,
	},
	TileType.DARK_GRASS: {
		"atlas": Vector2i(2, 1),
		"walkable": true,
		"walk_speed": 1.0,
	},
}

enum Biome {
	FOREST,
	PLAINS,
	DESERT
}

var terrain_noise = FastNoiseLite.new()
var biome_noise = FastNoiseLite.new()

func _init():
	# créer une seed aléatoire à chaque lancement
	terrain_noise.frequency = 0.005
	#terrain_noise.seed = randi()
	terrain_noise.seed = 367317914
	print("Seed : ", terrain_noise.seed)

	biome_noise.frequency = terrain_noise.frequency / 3
	biome_noise.seed = terrain_noise.seed + 1000

func get_tile_type(world_x: int, world_y: int) -> TileType:

	var height := terrain_noise.get_noise_2d(world_x, world_y)
	var biome := get_biome(world_x, world_y)

	if height < -0.2:
		return TileType.WATER
	
	if biome == Biome.DESERT:
		return TileType.SAND
	
	if biome == Biome.FOREST:
		return TileType.DARK_GRASS
	
	return TileType.GRASS

func get_biome(x: int, y: int) -> Biome:

	var b = biome_noise.get_noise_2d(x, y)

	if b < -0.3:
		return Biome.DESERT
	elif b < 0.3:
		return Biome.PLAINS
	else:
		return Biome.FOREST

func get_walk_speed(tile_type: int) -> float:
	return TILE_DEFS[tile_type]["walk_speed"]
