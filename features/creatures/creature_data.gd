extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

enum CreatureSize {
	SMALL,  ## Layer 4 "Small creatures" - collides with terrain, player, and other creatures.
	BIG     ## Layer 5 "Big creatures" - collides with terrain and other big creatures only.
}

enum MovementType {
	DEFAULT,  ## Legacy/default movement strategy (same as walk speed, used for "first available" fallback).
	HOP,
	FLY,
	SNEAK,
	WALK,
	RUN,
	SPRINT,
}

@export var id: StringName = ""
@export var display_name: String = ""
@export var sprite: Texture2D
@export var goals: Array[Goal] = []
@export var sensors: Array[Sensor] = []
@export var size_type: CreatureSize = CreatureSize.SMALL
@export var can_fly: bool = false
@export var can_swim: bool = false
@export var scale_factor: float = 1.0
@export var size: int = 16
@export var hitbox_size: int = 16
@export var base_speed: float = 40.0
@export var running_multiplier: float = 2.0
@export var hop_multiplier: float = 1.0
@export var rotating_speed: float = TAU
@export var biomes: Array[WorldGenerator.Biome] = [WorldGenerator.Biome.FOREST, WorldGenerator.Biome.PLAINS]
@export var excluded_tile_types: Array[WorldGenerator.TileType] = [WorldGenerator.TileType.WATER]
@export var movement_types: Array[MovementType] = [MovementType.RUN]
@export var needs_eating: bool = false
## Item types this species can eat; used by [FoodSensor] when [member needs_eating] is true.
@export var edible_items: Array[ItemData] = []
## Prey species ([CreatureData]) this species can eat; used by [FoodSensor].
@export var edible_creatures: Array[CreatureData] = []
@export var hunger_decay_rate: float = 5.0
@export var taming_decay_rate: float = 5.0
@export var taming_value_threshold: int = 0
@export var hit_damage: int = 1
@export var attack_range: float = Constants.DEFAULT_COMBAT_APPROACH_STANDOFF
@export var attack_cooldown: float = 0.8
