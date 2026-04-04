extends Node


func do_pickup(by: Node, world_object: WorldObject) -> bool:

	if world_object == null or by == null:
		return false

	if not PickableBehavior.has_behavior(world_object):
		return false

	EventManager.object_picked_up.emit(by, world_object)

	world_object.destroy("picked_up")
	return true


func do_eat(by: Node, world_object: WorldObject) -> bool:

	if world_object == null or by == null:
		return false
	
	if world_object.object_data == null:
		return false

	# Player does not eat world objects; use inventory consume instead.
	if by is Player:
		return false

	# Creature eating: current behavior is to refill hunger to max.
	if by is Creature:
		var creature := by as Creature
		creature.needs_component.set_need_value(NeedIds.HUNGER, NeedInstance.MAX_VALUE)
		EventManager.object_eaten.emit(creature, world_object)
		world_object.destroy("eaten")
		return true

	return false


func apply_food_amount_to_player(player: Player, amount: float) -> void:
	if amount <= 0.0 or player.is_dead():
		return
	var room := player.player_config.max_hunger - player.hunger
	var to_hunger := minf(amount, room)
	if to_hunger > 0.0:
		player.hunger += to_hunger
		player.hunger_changed.emit(player.hunger)
	var overflow := amount - to_hunger
	if overflow > 0.0:
		var prev_health := player.health
		player.health = minf(player.player_config.max_health, player.health + overflow)
		if player.health != prev_health:
			player.health_changed.emit(player.health)
