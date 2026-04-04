extends Resource
class_name BiomeCreatureSpawnProfile

@export var biome: int = TerrainGenerator.Biome.NONE
@export var creature_weights: Dictionary[CreatureData, float] = {}

func get_weight(creature: CreatureData) -> float:
	# Missing entries are treated as weight 0.
	return creature_weights.get(creature, 0.0)
