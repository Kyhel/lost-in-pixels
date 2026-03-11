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
## SMALL = layer 4, BIG = layer 5. Determines collision layer and mask (see Creature._ready).
@export var size: CreatureSize = CreatureSize.SMALL
## Higher priority can push lower. Same priority cannot push each other. Used with PushPriorityHelper.
@export var push_priority: int = 0
