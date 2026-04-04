class_name TerrainDefinition

var atlas: Vector2i
var walkable: bool
var swimmable: bool
var walk_speed: float

func _init(
	p_atlas: Vector2i = Vector2i.ZERO,
	p_walkable: bool = false,
	p_swimmable: bool = false,
	p_walk_speed: float = 0.0
) -> void:
	atlas = p_atlas
	walkable = p_walkable
	swimmable = p_swimmable
	walk_speed = p_walk_speed
