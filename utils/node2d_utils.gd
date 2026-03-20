class_name Node2DUtils

static func get_closest(point: Vector2, nodes: Array[Node2D]) -> Node2D:

	"""Returns the Node2D from [param nodes] closest to [param point]."""

	var closest: Node2D = nodes[0]
	var min_dist_sq: float = point.distance_squared_to(closest.global_position)
	for node in nodes:
		var d_sq := node.global_position.distance_squared_to(point)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			closest = node

	return closest

static func is_within_interaction_range(creature: Creature, target: Node2D, margin: float = 4.0) -> bool:
	var actor_radius: float = creature.get_hitbox_radius()
	var target_radius: float = get_collision_radius(target)
	var threshold: float
	if target_radius > 0.0:
		threshold = actor_radius + target_radius + margin
	else:
		threshold = actor_radius + margin
	return creature.global_position.distance_to(target.global_position) < threshold

static func get_collision_radius(node: Node2D) -> float:
	return _get_radius(node)

static func _get_radius(node: Node2D) -> float:
	for child in node.get_children():
		if child is CollisionShape2D:
			var shape_node := child as CollisionShape2D
			var shape = shape_node.shape
			if shape is CircleShape2D:
				var radius: float = (shape as CircleShape2D).radius
				var scale_vec: Vector2 = shape_node.global_transform.get_scale()
				var scale_max: float = max(scale_vec.x, scale_vec.y)
				return radius * scale_max
	return 0.0
