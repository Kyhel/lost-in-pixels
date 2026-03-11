class_name PushPriorityHelper

## Push-priority: lower priority gets pushed by higher. Player has [constant PLAYER_PRIORITY].
## - Player pushes only creatures with push_priority < PLAYER_PRIORITY (e.g. birds).
## - Creatures with push_priority > PLAYER_PRIORITY (e.g. big_wandering) don't get pushed by the player
##   and push the player away when they overlap (their collision_mask excludes player so they can overlap).
##
## Pushes use the minimum distance so shapes no longer overlap (no visible bounce).

const PLAYER_PRIORITY: int = 1


## Returns the radius of the first CircleShape2D on [param node], or 0.0 if none.
static func _get_radius(node: Node2D) -> float:
	for child in node.get_children():
		if child is CollisionShape2D:
			var shape = (child as CollisionShape2D).shape
			if shape is CircleShape2D:
				return (shape as CircleShape2D).radius
	return 0.0


## Call after the player's move_and_slide(). Pushes away overlapping [Creature]s that have
## push_priority < [constant PLAYER_PRIORITY] (e.g. birds), by the minimum distance so circles just touch.
static func push_away_creatures_overlapping(body: CharacterBody2D) -> void:
	var space = body.get_world_2d().direct_space_state
	if space == null:
		return
	var shape_node: CollisionShape2D = null
	for child in body.get_children():
		if child is CollisionShape2D:
			shape_node = child as CollisionShape2D
			break
	if shape_node == null or shape_node.shape == null:
		return

	var body_radius: float = _get_radius(body)
	if body_radius <= 0.0:
		return

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = body.global_transform
	params.collision_mask = 4  # layer 3 (Enemies/Creatures)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.exclude = [body.get_rid()]

	var results: Array = space.intersect_shape(params)
	for result in results:
		var collider = result.collider
		if collider is Creature:
			var c: Creature = collider as Creature
			if c.creature_data != null and c.creature_data.push_priority >= PLAYER_PRIORITY:
				continue  # Don't push higher-or-equal priority (e.g. big_wandering)
			var other_radius: float = _get_radius(collider as Node2D)
			var to_other: Vector2 = (collider as Node2D).global_position - body.global_position
			var dist: float = to_other.length()
			var min_dist: float = body_radius + other_radius
			if dist < min_dist and dist > 0.0001:
				var dir: Vector2 = to_other / dist
				var push: float = min_dist - dist
				(collider as CharacterBody2D).global_position += dir * push
			elif dist <= 0.0001:
				(collider as CharacterBody2D).global_position += Vector2.RIGHT * min_dist


## Call after a high-priority creature's move_and_slide(). If [param creature] has push_priority >
## [constant PLAYER_PRIORITY] and overlaps the player, pushes the player away by the minimum distance.
static func push_away_player_overlapping(creature: CharacterBody2D) -> void:
	if creature is Creature == false:
		return
	var c: Creature = creature as Creature
	if c.creature_data == null or c.creature_data.push_priority <= PLAYER_PRIORITY:
		return
	var space: PhysicsDirectSpaceState2D = creature.get_world_2d().direct_space_state
	if space == null:
		return
	var shape_node: CollisionShape2D = null
	for child in creature.get_children():
		if child is CollisionShape2D:
			shape_node = child as CollisionShape2D
			break
	if shape_node == null or shape_node.shape == null:
		return
	var creature_radius: float = _get_radius(creature)
	if creature_radius <= 0.0:
		return
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = creature.global_transform
	params.collision_mask = 1  # layer 1 (Player)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.exclude = [creature.get_rid()]
	var results: Array = space.intersect_shape(params)
	for result in results:
		var player_body = result.collider
		if player_body is CharacterBody2D == false:
			continue
		var player_radius: float = _get_radius(player_body as Node2D)
		var to_player: Vector2 = (player_body as Node2D).global_position - creature.global_position
		var dist: float = to_player.length()
		var min_dist: float = creature_radius + player_radius
		if dist < min_dist and dist > 0.0001:
			var dir: Vector2 = to_player / dist
			var push: float = min_dist - dist
			(player_body as CharacterBody2D).global_position += dir * push
		elif dist <= 0.0001:
			(player_body as CharacterBody2D).global_position += Vector2.RIGHT * min_dist
		return  # At most one player
