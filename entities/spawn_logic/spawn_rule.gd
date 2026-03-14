class_name SpawnRule
extends Resource

func can_spawn(world_pos: Vector2, context: Dictionary) -> bool:
	return true

func probability_modifier(world_pos: Vector2, context: Dictionary) -> float:
	return 1.0
