extends Node


func do_pickup(by: Node, world_object: WorldObject) -> bool:

	if world_object == null or by == null:
		return false
	if world_object.object_data == null:
		return false
	if not world_object.object_data.can_pickup:
		return false
	if not world_object.can_be_picked_up(by):
		return false

	EventManager.object_picked_up.emit(by, world_object)

	world_object.picked_up.emit(by)
	world_object.destroy("picked_up")
	return true


func do_eat(by: Node, world_object: WorldObject) -> bool:

	if world_object == null or by == null:
		return false
	
	if world_object.object_data == null:
		return false

	# Player eating: only succeeds when it won't overfill hunger.
	if by is Player:
		_apply_player_eat_food(by as Player, float(_player_food_value(world_object.object_data)))
		world_object.destroy("eaten")
		return true

	# Creature eating: current behavior is to refill hunger to max.
	if by is Creature:
		var creature := by as Creature
		creature.blackboard.set_value(Blackboard.KEY_HUNGER, Blackboard.KEY_HUNGER_MAX)
		EventManager.object_eaten.emit(creature, world_object)
		world_object.destroy("eaten")
		return true

	return false


func _player_food_value(od: ObjectData) -> int:
	for b in od.behaviors:
		if b is PlayerEatableBehavior:
			return (b as PlayerEatableBehavior).player_food_value
	return 0


func _apply_player_eat_food(player: Player, amount: float) -> void:
	if amount <= 0.0 or player.is_dead():
		return
	var room := player.max_hunger - player.hunger
	var to_hunger := minf(amount, room)
	if to_hunger > 0.0:
		player.hunger += to_hunger
		player.hunger_changed.emit(player.hunger)
	var overflow := amount - to_hunger
	if overflow > 0.0:
		var prev_health := player.health
		player.health = minf(player.max_health, player.health + overflow)
		if player.health != prev_health:
			player.health_changed.emit(player.health)
