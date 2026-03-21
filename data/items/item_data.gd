extends Resource
class_name ItemData

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var texture: Texture2D

@export var stackable: bool = false
@export var max_stack: int = 1
@export var taming_value: int = 0

# Player
@export var can_pickup: bool = false
@export var player_food_value: int = 0

## World pickup radius (pixels); drives [WorldItem] sprite and collision scale (base circle radius 1 in scene).
@export var hitbox_radius: float = 4.0

@export var spawn_definition: SpawnDefinition

# Optional effect scripts for modular behavior.
# These scripts can implement methods like:
# - func on_pickup(world_item, by)
# - func on_use(world_item, user, target)
# - func on_destroy(world_item, reason)
@export var pickup_effect_script: Script
@export var use_effect_script: Script
@export var destroy_effect_script: Script
