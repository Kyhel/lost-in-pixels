class_name ObjectData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var texture: Texture2D

@export var taming_value: int = 0

# Player
@export var can_pickup: bool = false
@export var player_food_value: int = 0

## Item granted to the player inventory when this object is picked up (player only).
@export var on_pickup_item: ItemData

## World pickup radius (pixels); drives [WorldObject] sprite and collision scale (base circle radius 1 in scene).
@export var hitbox_radius: float = 4.0

@export var spawn_definition: SpawnDefinition

# Optional effect scripts for modular behavior.
# These scripts can implement methods like:
# - func on_pickup(world_object, by)
# - func on_use(world_object, user, target)
# - func on_destroy(world_object, reason)
@export var pickup_effect_script: Script
@export var use_effect_script: Script
@export var destroy_effect_script: Script
