extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

enum CreatureSize {
	SMALL,  ## Layer 4 "Small creatures" - collides with terrain, player, and other creatures.
	BIG     ## Layer 5 "Big creatures" - collides with terrain and other big creatures only.
}

@export var display_name: String = ""
@export var sprite: Texture2D
@export var behavior_tree: PackedScene
@export var sensor_scenes: Array[PackedScene] = []  ## Sensor scenes (e.g. FoodSensor); each runs every tick and writes to the creature's blackboard. Root node must be a [Sensor].
@export var goals: Array[Goal] = []
@export var size_type: CreatureSize = CreatureSize.SMALL
@export var can_fly: bool = false
@export var scale_factor: float = 1.0
@export var size: int = 16
@export var walking_speed: float = 40.0
@export var rotating_speed: float = TAU
@export var biomes: Array[WorldGenerator.Biome] = []
@export var excluded_tile_types: Array[WorldGenerator.TileType] = []
