class_name FearNeed
extends Need

const FEAR_THRESHOLD: float = 80.0

@export var fear_buildup_rate: float = 0.0
@export var fear_player_distance: float = 0.0


func update(creature: Creature, instance: NeedInstance, delta: float) -> void:
	if fear_player_distance <= 0.0:
		return

	var fear := instance.current_value
	var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	if player == null:
		fear = maxf(0.0, fear - base_decay_rate * delta)
		instance.set_value(fear)
		return

	var dist := creature.global_position.distance_to(player.global_position)
	var tamed: bool = creature.blackboard.get_value(Blackboard.KEY_TAMED, false)
	if dist < fear_player_distance and not tamed:
		fear = minf(100.0, fear + fear_buildup_rate * delta)
	else:
		fear = maxf(0.0, fear - base_decay_rate * delta)
	instance.set_value(fear)
