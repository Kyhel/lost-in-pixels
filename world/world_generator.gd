extends Node
class_name WorldGenerator

enum TileType {
	WATER,
	SAND,
	GRASS,
	DARK_GRASS,
	SNOW,
	LAVA,
	TOXIC,
	BEACH,
	DEAD,
	SWAMP,
	TUNDRA,
	DANGER_COLD_DRY,
	DANGER_COLD_MOIST,
}

const TILE_DEFS = {
	TileType.WATER: {
		"atlas": Vector2i(2, 0),
		"walkable": false,
		"swimmable": true,
		"walk_speed": 0.5,
	},
	TileType.BEACH: {
		"atlas": Vector2i(3, 0),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 0.6,
	},
	TileType.SNOW: {
		"atlas": Vector2i(4, 0),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 0.5,
	},
	TileType.SWAMP: {
		"atlas": Vector2i(0, 1),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.TUNDRA: {
		"atlas": Vector2i(1, 1),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.GRASS: {
		"atlas": Vector2i(2, 1),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.DARK_GRASS: {
		"atlas": Vector2i(3, 1),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.SAND: {
		"atlas": Vector2i(4, 1),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 0.6,
	},
	TileType.DANGER_COLD_MOIST: {
		"atlas": Vector2i(0, 2),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.DANGER_COLD_DRY: {
		"atlas": Vector2i(1, 2),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.DEAD: {
		"atlas": Vector2i(2, 2),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.TOXIC: {
		"atlas": Vector2i(3, 2),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
	TileType.LAVA: {
		"atlas": Vector2i(4, 2),
		"walkable": true,
		"swimmable": false,
		"walk_speed": 1.0,
	},
}

enum Biome {
	FOREST,
	PLAINS,
	DESERT,
	MOUNTAIN,
	LAVA,
	TOXIC,
	WATER,
	DEAD,
	SWAMP,
	TUNDRA,
}

var terrain_noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()

var noise_wavelength := 50.0

var world_generator_2 := WorldGenerator2.new()

func _init() -> void:
	terrain_noise.frequency = 1 / noise_wavelength
	biome_noise.frequency = terrain_noise.frequency / 3


func setup_seed(p_seed: int) -> void:
	terrain_noise.seed = p_seed
	biome_noise.seed = p_seed + 1000
	world_generator_2.setup_seed(p_seed)


func get_tile_type(world_x: int, world_y: int) -> TileType:

	return world_generator_2.get_tile(world_x, world_y)


func get_biome(world_x: int, world_y: int) -> Biome:

	var tile_type = world_generator_2.get_tile(world_x, world_y)

	match tile_type:
		WorldGenerator.TileType.WATER:
			return Biome.WATER
		WorldGenerator.TileType.BEACH:
			return Biome.WATER
		WorldGenerator.TileType.GRASS:
			return Biome.PLAINS
		WorldGenerator.TileType.DARK_GRASS:
			return Biome.FOREST
		WorldGenerator.TileType.SAND:
			return Biome.DESERT
		WorldGenerator.TileType.SNOW:
			return Biome.MOUNTAIN
		WorldGenerator.TileType.LAVA:
			return Biome.LAVA
		WorldGenerator.TileType.TOXIC:
			return Biome.TOXIC
		WorldGenerator.TileType.DEAD:
			return Biome.DEAD
		WorldGenerator.TileType.SWAMP:
			return Biome.SWAMP
		WorldGenerator.TileType.TUNDRA:
			return Biome.TUNDRA
		_:
			return Biome.PLAINS


func get_walk_speed(tile_type: int) -> float:
	return TILE_DEFS[tile_type]["walk_speed"]
