class_name PlayerSensor
extends Sensor

@export var scan_radius: float = 150.0

func update(creature: Creature) -> void:

	if creature.blackboard == null:
		print("Blackboard is null")
		return

	var player: Player = creature.get_tree().get_first_node_in_group(Groups.PLAYER)

	if player == null:
		creature.blackboard.set_value(Blackboard.KEY_SEES_PLAYER, false)
		return

	var distance = creature.global_position.distance_to(player.global_position)

	creature.blackboard.set_value(Blackboard.KEY_SEES_PLAYER, distance <= scan_radius)
