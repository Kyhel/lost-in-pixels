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
@export var size_type: CreatureSize = CreatureSize.SMALL
@export var scale_factor: float = 1.0
@export var size: int = 16
