class_name CreatureUtils

## Same tile + walkability checks as [WanderAction] for wander/flee destinations.
static func is_valid_wander_destination(creature: Creature, world_pos: Vector2) -> bool:
	var data := creature.creature_data
	if data == null:
		return false
	var tile_type := ChunkManager.get_tile_type_at_world_pos(world_pos)
	if not data.navigable_terrain_types.is_empty() and not data.navigable_terrain_types.has(tile_type):
		return false
	if not _passes_terrain_preference_traits(data, world_pos):
		return false
	return ChunkManager.is_area_walkable_for_creature(
			creature, world_pos, data.hitbox_size
		) and not ChunkManager.is_environment_blocking_creature(creature, world_pos)


static func _passes_terrain_preference_traits(data: CreatureData, world_pos: Vector2) -> bool:
	var tile_coords := ChunkManager.world_pos_to_world_tile(world_pos)
	for trait_res in data.traits:
		if trait_res == null:
			continue
		var terrain_trait := trait_res as TerrainPreferenceTrait
		if terrain_trait == null:
			continue
		if not terrain_trait.is_tile_valid(tile_coords):
			return false
	return true
