class_name Vector2Utils

## Static utility functions for Vector2 operations.

static func get_closest(point: Vector2, points: Array[Vector2]) -> Vector2:

	"""Returns the Vector2 from [param points] closest to [param point]."""

	var closest: Vector2 = points[0]
	var min_dist_sq: float = point.distance_squared_to(closest)
	for p in points:
		var d_sq := point.distance_squared_to(p)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			closest = p

	return closest
