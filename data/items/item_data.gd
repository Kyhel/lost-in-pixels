extends Resource
class_name ItemData

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var region: Rect2 = Rect2(0, 0, 16, 16)

@export var texture: Texture2D

@export var stackable: bool = false
@export var max_stack: int = 1

# Optional effect scripts for modular behavior.
# These scripts can implement methods like:
# - func on_pickup(world_item, by)
# - func on_use(world_item, user, target)
# - func on_destroy(world_item, reason)
@export var pickup_effect_script: Script
@export var use_effect_script: Script
@export var destroy_effect_script: Script
