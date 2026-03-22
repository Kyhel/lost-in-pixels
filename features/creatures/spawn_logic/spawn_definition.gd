extends Resource
class_name SpawnDefinition

@export var biomes: Array[WorldGenerator.Biome] = []
@export var excluded_tile_types: Array[WorldGenerator.TileType] = []
@export var spawn_rules: Array[SpawnRule] = []
