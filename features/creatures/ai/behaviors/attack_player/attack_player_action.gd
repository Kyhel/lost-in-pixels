class_name AttackPlayerAction
extends BTNode

var creature_hit_player_effect_scene := preload("res://features/creatures/visual_effects/creature_hit_player_effect.tscn")
var attack_cooldown_timer: float = 0.0

func tick(creature: Creature, delta: float) -> State:
	if creature.blackboard.get_value(Blackboard.KEY_SEES_PLAYER) != true:
		creature.movement.stop()
		return State.FAILURE

	var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Player
	if player == null:
		creature.movement.stop()
		return State.FAILURE

	if not _is_player_in_attack_range(creature, player):
		return State.FAILURE

	# Keep facing/holding while waiting to attack again.
	creature.movement.request_movement(MovementRequest.to_combat_engage(player, 1.0))

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		return State.RUNNING

	player.take_damage(creature.creature_data.hit_damage, creature)
	_spawn_hit_player_effect(creature, player)
	attack_cooldown_timer = creature.creature_data.attack_cooldown
	return State.RUNNING

func reset() -> void:
	super.reset()
	attack_cooldown_timer = 0.0

func _is_player_in_attack_range(creature: Creature, player: Player) -> bool:
	return Node2DUtils.is_within_interaction_range(
		creature,
		player,
		creature.creature_data.attack_range
	)


func _spawn_hit_player_effect(creature: Creature, player: Player) -> void:
	var to_creature := creature.global_position - player.global_position
	if to_creature.is_zero_approx():
		to_creature = Vector2.UP
	var hit_direction := to_creature.normalized()
	var hit_distance := player.get_hitbox_radius()
	var spawn_pos := player.global_position + hit_direction * hit_distance

	var fx := creature_hit_player_effect_scene.instantiate() as Node2D
	fx.global_position = spawn_pos
	fx.rotation = hit_direction.angle()
	creature.get_tree().current_scene.add_child(fx)
