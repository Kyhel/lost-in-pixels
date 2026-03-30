class_name CreatureUtils

## Same tile + walkability checks as [WanderAction] for wander/flee destinations.
static func is_valid_wander_destination(creature: Creature, world_pos: Vector2) -> bool:
	var data := creature.creature_data
	if data == null:
		return false
	var tile_type := ChunkManager.get_tile_type_at_world_pos(world_pos)
	if data.excluded_tile_types.has(tile_type):
		return false
	if not data.allowed_wander_tiles.is_empty() and not data.allowed_wander_tiles.has(tile_type):
		return false
	return ChunkManager.is_area_walkable_for_creature(
			creature, world_pos, data.hitbox_size
		) and not ChunkManager.is_environment_blocking_creature(creature, world_pos)
