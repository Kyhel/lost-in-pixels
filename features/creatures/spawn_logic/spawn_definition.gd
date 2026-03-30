extends Resource
class_name SpawnDefinition

@export var biomes: Array[TerrainGenerator.Biome] = []
@export var excluded_tile_types: Array[Terrain.Type] = []
@export var spawn_rules: Array[SpawnRule] = []
