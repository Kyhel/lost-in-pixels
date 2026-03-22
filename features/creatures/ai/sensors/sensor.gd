class_name Sensor
extends Resource

## Base class for creature sensors (like a Java interface).
## Subclasses override [method update] to run their detection logic and write results to [member Creature.blackboard].

## Called each tick by the creature. Override to scan the world and store results in [param creature].blackboard.
func update(_creature: Creature) -> void:
	pass
