extends Node

## Root of a behavior tree. Ticks the first child (root behavior) each frame.
## Attach this scene as a child of a Creature; the creature calls [method tick] from _physics_process.

func tick(creature: Creature, delta: float) -> void:
	var children = get_children()
	if children.size() > 0:
		var root_behavior = children[0]
		if root_behavior.has_method("tick"):
			root_behavior.tick(creature, delta)
