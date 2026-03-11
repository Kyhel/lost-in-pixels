extends Resource
class_name CreatureData

## Data resource for a creature type: display name, sprite, and optional behavior tree.

@export var display_name: String = ""
@export var sprite: Texture2D
@export var behavior_tree: PackedScene
