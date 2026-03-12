class_name Goal
extends Resource

@export var behavior_tree: PackedScene
@export var weight := 1.0

func get_score(_creature: Creature) -> float:
	return 0.0
