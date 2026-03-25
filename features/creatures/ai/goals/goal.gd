class_name Goal
extends Resource

@export var behavior_tree: PackedScene
@export var weight := 1.0
@export var tags: Array[String] = []

func get_score(_creature: Creature) -> float:
	return 0.0

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func update(_creature: Creature, _delta: float) -> void:
	pass
