class_name SpawnRule
extends Resource

func can_spawn(_world_pos: Vector2, _context: Dictionary) -> bool:
	return true

func probability_modifier(_world_pos: Vector2, _context: Dictionary) -> float:
	return 1.0
