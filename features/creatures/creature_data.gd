extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

enum CreatureSize {
	SMALL,  ## Layer 4 "Small creatures" - collides with terrain, player, and other creatures.
	BIG     ## Layer 5 "Big creatures" - collides with terrain and other big creatures only.
}

@export var id: StringName = ""
@export var display_name: String = ""
@export var sprite: Texture2D
## Goal resource -> priority. Only these goals are considered by AI; missing value resolves to 0 in code.
@export var goals: Dictionary[Goal, int] = {}
@export var sensors: Array[Sensor] = []
## Per-species need definitions (hunger, fear, taming, etc.). Carnivores/herbivores: configure edibles on [HungerNeed].
@export var needs: Array[Need] = []
## Per-species trait definitions (terrain preferences, special movement constraints, etc.).
@export var traits: Array[CreatureTrait] = []
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
@export var biomes: Array[TerrainGenerator.Biome] = [TerrainGenerator.Biome.FOREST, TerrainGenerator.Biome.PLAINS]
@export var excluded_tile_types: Array[Terrain.Type] = [Terrain.Type.WATER]
## If non-empty, wander destination tiles must be one of these. If empty, no tile-type restriction is applied.
@export var navigable_terrain_types: Array[Terrain.Type] = []
## Per-context scoring; first profile is used when no entry matches [member MovementRequest.context].
@export var movement_profiles: Array[MovementProfile] = [
	preload("res://features/creatures/movement/profiles/defaults/default_movement_profile.tres")
]
@export var hit_damage: int = 1
@export var attack_range: float = Constants.DEFAULT_COMBAT_APPROACH_STANDOFF
@export var attack_cooldown: float = 0.8
## Per second toward 100 while the player is seen; 0 = attack as soon as the player is visible (no meter).
@export var aggressiveness_buildup_rate: float = 0.0
@export var aggressiveness_decay_rate: float = 10.0


func get_priority_for_goal(goal: Goal) -> int:
	if not goals.has(goal):
		return 0
	return int(goals[goal])
