class_name FollowPlayerGoal
extends Goal

func get_score(creature: Creature) -> float:

	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return 0.0

	var player = creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	if player == null:
		return 0.0

	var distance_to_player := creature.global_position.distance_to(player.global_position)

	if distance_to_player >= FollowPlayerAction.ORBIT_ZONE_MAX * 4:
		return 0.5

	return 0.05
