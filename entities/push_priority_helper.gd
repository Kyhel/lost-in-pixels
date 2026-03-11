class_name PushPriorityHelper

## Push-priority is handled via collision layers so the engine does the work:
## - Player does not collide with creatures (mask = terrain only), so the player is never blocked by them.
## - Creatures collide with the player (and terrain), so they are blocked by the player and never push them.
##
## After the player moves, call [method push_away_creatures_overlapping] to displace any creatures
## the player overlaps (so the player effectively "pushes" them). Pushes by the minimum amount
## so collision shapes no longer overlap (no visible bounce).


## Returns the radius of the first CircleShape2D on [param node], or 0.0 if none.
static func _get_radius(node: Node2D) -> float:
	for child in node.get_children():
		if child is CollisionShape2D:
			var shape = (child as CollisionShape2D).shape
			if shape is CircleShape2D:
				return (shape as CircleShape2D).radius
	return 0.0


## Call after the player's move_and_slide(). Finds any [Creature] overlapping [param body] and
## moves them away by the minimum distance so their collision circles just touch (no overlap).
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
