class_name Unnamed1AttackPlayerGoal
extends AttackPlayerGoal

func get_score(creature: Creature) -> float:
	var tile: WorldGenerator.TileType = ChunkManager.get_tile_type_at_world_pos(creature.global_position)
	if tile != WorldGenerator.TileType.DARK_GRASS:
		var raw_agg = creature.blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS)
		if raw_agg != null and float(raw_agg) > 0.0:
			creature.blackboard.set_value(Blackboard.KEY_AGGRESSIVENESS_RECOVERING, true)
		return 0.0
	return super.get_score(creature)
