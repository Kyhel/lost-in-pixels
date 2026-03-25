class_name AttackPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:

	# Use != true so missing/null is treated as "does not see" (null == false is false in GDScript).
	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER, false):
		return 0

	if creature.creature_data == null or creature.creature_data.aggressiveness_buildup_rate <= 0.0:
		return 10.0

	if creature.blackboard.get_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.IDLE) == Blackboard.ChasingState.CHASING:
		return 10.0

	return 0.0

func update(creature: Creature, delta: float) -> void:

	var creature_data = creature.creature_data
	var blackboard = creature.blackboard

	if creature_data == null or blackboard == null:
		return

	if creature_data.aggressiveness_buildup_rate <= 0.0:
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

	var creature_data = creature.creature_data
	var blackboard = creature.blackboard

	if creature_data == null or blackboard == null:
		return

	# If the creature does not see the player, stop chasing
	var sees_player = blackboard.get_value(Blackboard.KEY_SEES_PLAYER, false)
	if not sees_player:
		blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.RECOVERING)
		return


func update_idle_state(creature: Creature, delta: float) -> void:

	var creature_data = creature.creature_data
	var blackboard = creature.blackboard

	if creature_data == null or blackboard == null:
		return

	# If the creature sees the player, buildup aggressiveness
	var sees_player = blackboard.get_value(Blackboard.KEY_SEES_PLAYER, false)
	if sees_player:
		increase_aggressiveness(blackboard, creature_data.aggressiveness_buildup_rate, delta)

	if blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS, 0.0) >= 100.0:
		blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.CHASING)
		return


func update_recovering_state(blackboard: Blackboard, creature_data: CreatureData, delta: float) -> void:
	
	decrease_aggressiveness(blackboard, creature_data.aggressiveness_decay_rate, delta)

	if blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS, 0.0) <= 0.0:
		blackboard.set_value(Blackboard.KEY_CHASING_STATE, Blackboard.ChasingState.IDLE)
		return

func increase_aggressiveness(blackboard: Blackboard, creature_aggressiveness_buildup_rate: float, delta: float) -> void:
	var aggressiveness = blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS, 0.0)
	aggressiveness = minf(100.0, aggressiveness + creature_aggressiveness_buildup_rate * delta)
	blackboard.set_value(Blackboard.KEY_AGGRESSIVENESS, aggressiveness)

func decrease_aggressiveness(blackboard: Blackboard, creature_aggressiveness_decay_rate: float, delta: float) -> void:
	var aggressiveness = blackboard.get_value(Blackboard.KEY_AGGRESSIVENESS, 0.0)
	aggressiveness = maxf(0.0, aggressiveness - creature_aggressiveness_decay_rate * delta)
	blackboard.set_value(Blackboard.KEY_AGGRESSIVENESS, aggressiveness)
