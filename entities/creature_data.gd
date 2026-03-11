extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

@export var display_name: String = ""
@export var sprite: Texture2D
@export var behavior_tree: PackedScene
## Higher priority can push lower. Same priority cannot push each other. Used with PushPriorityHelper.
@export var push_priority: int = 0
