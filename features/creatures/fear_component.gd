class_name FearComponent
extends RefCounted

func update(creature: Creature, delta: float) -> void:
	var data := creature.creature_data
	if data == null or data.fear_player_distance <= 0.0:
		return

	var blackboard := creature.blackboard
	var fear := float(blackboard.get_value(Blackboard.KEY_FEAR, 0.0))

	var player := creature.get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Node2D
	if player == null:
		fear = maxf(0.0, fear - data.fear_decay_rate * delta)
		blackboard.set_value(Blackboard.KEY_FEAR, fear)
		return

	var dist := creature.global_position.distance_to(player.global_position)
	var tamed : bool = blackboard.get_value(Blackboard.KEY_TAMED, false)
	if dist < data.fear_player_distance and not tamed:
		fear = minf(100.0, fear + data.fear_buildup_rate * delta)
	else:
		fear = maxf(0.0, fear - data.fear_decay_rate * delta)

	blackboard.set_value(Blackboard.KEY_FEAR, fear)
