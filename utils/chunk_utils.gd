class_name ChunkUtils

static func world_pos_to_world_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / float(Chunk.TILE_SIZE))),
		int(floor(world_pos.y / float(Chunk.TILE_SIZE)))
	)


static func world_tile_to_world_pos(world_tile: Vector2i) -> Vector2:
	return world_tile * Chunk.TILE_SIZE


static func world_tile_to_world_center(world_tile: Vector2i) -> Vector2:
	return world_tile_to_world_pos(world_tile) + Chunk.TILE_HALF_SIZE_VECTOR


static func world_pos_to_chunk_coords(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / float(Chunk.CHUNK_SIZE * Chunk.TILE_SIZE))),
		int(floor(pos.y / float(Chunk.CHUNK_SIZE * Chunk.TILE_SIZE)))
	)


static func world_tile_to_chunk_coords(world_tile: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(world_tile.x / float(Chunk.CHUNK_SIZE))),
		int(floor(world_tile.y / float(Chunk.CHUNK_SIZE)))
	)


static func world_tile_to_local_tile(world_tile: Vector2i) -> Vector2i:
	return Vector2i(
		posmod(world_tile.x, Chunk.CHUNK_SIZE),
		posmod(world_tile.y, Chunk.CHUNK_SIZE)
	)


static func get_chunk_coords_intersecting_circle(origin: Vector2, radius: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if radius < 0.0:
		return out
	var radius_sq := radius * radius
	var chunk_px := float(Chunk.CHUNK_SIZE * Chunk.TILE_SIZE)

	var min_x := origin.x - radius
	var max_x := origin.x + radius
	var min_y := origin.y - radius
	var max_y := origin.y + radius

	var min_cx := int(floor(min_x / chunk_px))
	var max_cx := int(floor(max_x / chunk_px))
	var min_cy := int(floor(min_y / chunk_px))
	var max_cy := int(floor(max_y / chunk_px))

	for cx in range(min_cx, max_cx + 1):
		for cy in range(min_cy, max_cy + 1):
			var rect_min := Vector2(float(cx), float(cy)) * chunk_px
			var rect_max := rect_min + Vector2(chunk_px, chunk_px)
			var nearest_x := clampf(origin.x, rect_min.x, rect_max.x)
			var nearest_y := clampf(origin.y, rect_min.y, rect_max.y)
			var ddx := origin.x - nearest_x
			var ddy := origin.y - nearest_y
			if ddx * ddx + ddy * ddy > radius_sq:
				continue
			out.append(Vector2i(cx, cy))

	return out
