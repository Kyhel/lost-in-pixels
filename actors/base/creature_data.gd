extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

enum CreatureSize {
	SMALL,  ## Layer 4 "Small creatures" - collides with terrain, player, and other creatures.
	BIG     ## Layer 5 "Big creatures" - collides with terrain and other big creatures only.
}

enum MovementType {
	HOP,
	FLY,
	SNEAK,
	WALK,
	RUN,
	SPRINT,
	DEFAULT  ## Legacy/default movement strategy (same as walk speed, used for "first available" fallback).
}

@export var display_name: String = ""
@export var sprite: Texture2D
@export var sensor_scenes: Array[PackedScene] = []  ## Sensor scenes (e.g. FoodSensor); each runs every tick and writes to the creature's blackboard. Root node must be a [Sensor].
@export var goals: Array[Goal] = []
@export var size_type: CreatureSize = CreatureSize.SMALL
@export var can_fly: bool = false
@export var scale_factor: float = 1.0
@export var size: int = 16
@export var base_speed: float = 40.0
@export var running_multiplier: float = 2.0
@export var sprinting_multiplier: float = 4.0  ## Default 2× running_multiplier; used when following at sprint distance.
@export var hop_multiplier: float = 1.0
@export var rotating_speed: float = TAU
@export var biomes: Array[WorldGenerator.Biome] = [WorldGenerator.Biome.FOREST, WorldGenerator.Biome.PLAINS]
@export var excluded_tile_types: Array[WorldGenerator.TileType] = [WorldGenerator.TileType.WATER]
@export var movement_types: Array[MovementType] = [MovementType.WALK]
@export var needs_eating: bool = false
@export var hunger_decay_rate: float = 5.0
@export var taming_decay_rate: float = 5.0
@export var taming_value_threshold: int = 100
