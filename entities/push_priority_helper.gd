class_name PushPriorityHelper

## Push-priority is handled via collision layers so the engine does the work:
## - Player does not collide with creatures (mask = terrain only), so the player is never blocked by them.
## - Creatures collide with the player (and terrain), so they are blocked by the player and never push them.
##
## After the player moves, call [method push_away_creatures_overlapping] to displace any creatures
## the player overlaps (so the player effectively "pushes" them).

const PUSH_AWAY_DISTANCE: float = 10.0  # enough to separate player and creature circles (radius 8 each)


## Call after the player's move_and_slide(). Finds any [Creature] overlapping [param body] and
## moves them away from [param body] so the player visually pushes lower-priority entities.
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
			var dir: Vector2 = (collider.global_position - body.global_position).normalized()
			if dir.length_squared() < 0.01:
				dir = Vector2.RIGHT  # fallback if same position
			(collider as CharacterBody2D).global_position += dir * PUSH_AWAY_DISTANCE
