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
