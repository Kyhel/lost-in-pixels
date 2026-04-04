extends Resource
class_name SpawnDefinition

## World object this definition applies to (realtime spawn in [SpawnSystem]).
@export var object_data: ObjectData

@export var biomes: Array[TerrainGenerator.Biome] = []
@export var excluded_tile_types: Array[Terrain.Type] = []
@export var spawn_rules: Array[SpawnRule] = []
