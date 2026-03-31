extends Node

## Autoload: creature targeting, interaction menu lifecycle, give/pet actions.

const CREATURE_INTERACTION_RANGE: float = 96.0

var _target_creature: Creature = null
var _we_paused: bool = false


func is_interaction_open() -> bool:
	return _target_creature != null and is_instance_valid(_target_creature)


func get_target_creature() -> Creature:
	if not is_instance_valid(_target_creature):
		return null
	return _target_creature


func begin_interaction(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	_target_creature = creature
	_we_paused = true
	get_tree().paused = true
	PlayerInputManager.set_creature_menu_open(true)
	var menu := _find_menu()
	if menu:
		menu.open_for_creature(creature)


func end_interaction() -> void:
	_target_creature = null
	if _we_paused:
		_we_paused = false
		get_tree().paused = false
	PlayerInputManager.set_creature_menu_open(false)
	var menu := _find_menu()
	if menu:
		menu.hide_menu()


func find_best_creature_target(player: Player) -> Creature:
	if player == null:
		return null
	var space := player.get_world_2d().direct_space_state
	var player_r: float = player.get_hitbox_radius()
	var radius: float = player_r + CREATURE_INTERACTION_RANGE
	var circle := CircleShape2D.new()
	circle.radius = radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, player.global_position)
	# Small + big creatures only (not flying layer).
	params.collision_mask = Layers.SMALL_CREATURES | Layers.BIG_CREATURES
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hits: Array[Dictionary] = space.intersect_shape(params, 64)

	var forward := Vector2.UP.rotated(player.sprite.rotation)
	if forward.is_zero_approx():
		forward = Vector2.UP

	var best: Creature = null
	var best_score: float = -1.0
	var d_max: float = radius
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or not collider is Creature:
			continue
		var c: Creature = collider as Creature
		var to_c: Vector2 = c.global_position - player.global_position
		var dist: float = to_c.length()
		if dist > d_max + 0.01:
			continue
		var creature_r: float = c.get_hitbox_radius()
		var d_touch: float = player_r + creature_r
		var angle_score: float = 0.0
		if dist < 0.001:
			angle_score = 1.0
		else:
			angle_score = clampf(forward.dot(to_c / dist), 0.0, 1.0)
		var distance_score: float = 0.0
		if dist <= d_touch:
			distance_score = 1.0
		elif dist >= d_max:
			distance_score = 0.0
		else:
			distance_score = 1.0 - (dist - d_touch) / maxf(d_max - d_touch, 0.0001)
		var total: float = angle_score + distance_score
		var better := total > best_score
		if not better and is_equal_approx(total, best_score) and best != null:
			better = dist < player.global_position.distance_to(best.global_position)
		if better:
			best_score = total
			best = c
	return best


func creature_receive_item_from_player(creature: Creature, item_id: StringName) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	if not Inventory.remove_item(item_id, 1):
		return
	var creature_name := _creature_display_name(creature)
	var item_data: ItemData = ItemDatabase.get_item_data(item_id)
	var item_name := item_data.display_name if item_data != null else String(item_id)
	GameLog.log_message("%s received %s from player" % [creature_name, item_name])


func creature_give_item_to_player(creature: Creature, item_id: StringName, amount: int = 1) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	if amount <= 0:
		return
	Inventory.add_item(item_id, amount)
	var creature_name := _creature_display_name(creature)
	var item_data: ItemData = ItemDatabase.get_item_data(item_id)
	var item_name := item_data.display_name if item_data != null else String(item_id)
	GameLog.log_message("%s gave %d %s to player" % [creature_name, amount, item_name])


func player_pet_creature(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	var creature_name := _creature_display_name(creature)
	GameLog.log_message("Player pet %s" % creature_name)


func _creature_display_name(creature: Creature) -> String:
	if creature.creature_data != null and not creature.creature_data.display_name.is_empty():
		return creature.creature_data.display_name
	return creature.name


func _find_menu() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("CreatureInteractionMenu", true, false)
