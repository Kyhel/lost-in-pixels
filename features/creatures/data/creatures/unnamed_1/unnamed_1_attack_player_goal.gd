class_name Unnamed1AttackPlayerGoal
extends AttackPlayerGoal


func update(creature: Creature, delta: float) -> void:

	var creature_data = creature.creature_data
	var blackboard = creature.blackboard

	if creature_data == null or blackboard == null:
		return

	match blackboard.get_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.IDLE):
		Blackboard.ChasingState.IDLE:
			update_idle_state(creature, delta)
		Blackboard.ChasingState.CHASING:
			update_chasing_state(creature)
		Blackboard.ChasingState.RECOVERING:
			update_recovering_state(blackboard, creature_data, delta)
		_:
			pass


func update_chasing_state(creature: Creature) -> void:

	# If the creature is chasing the player and reaches terrain without dark grass, stop  chasing
	var tile: WorldGenerator.TileType = ChunkManager.get_tile_type_at_world_pos(creature.global_position)
	if tile != WorldGenerator.TileType.DARK_GRASS:
		creature.blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.RECOVERING)
		return

	# If the creature does not see the player or the player is not on an aggressive tile, stop chasing
	var sees_player = creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER, false)
	var player_on_aggressive_tile = _player_on_aggressive_tile(creature)
	if not sees_player or not player_on_aggressive_tile:
		creature.blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.RECOVERING)
		return


func update_idle_state(creature: Creature, delta: float) -> void:

	# If the creature sees the player, buildup aggressiveness
	var sees_player = creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER, false)
	if sees_player:
		increase_aggressiveness(creature.blackboard, creature.creature_data.aggressiveness_buildup_rate, delta)
	
	var player_on_aggressive_tile = _player_on_aggressive_tile(creature)

	if creature.blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS, 0.0) >= 100.0 and player_on_aggressive_tile:
		creature.blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.CHASING)
		return


func _player_on_aggressive_tile(creature: Creature) -> bool:
	var player = creature.get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Player
	if player == null:
		return false
	var player_tile: WorldGenerator.TileType = ChunkManager.get_tile_type_at_world_pos(player.global_position)
	return player_tile == WorldGenerator.TileType.DARK_GRASS
