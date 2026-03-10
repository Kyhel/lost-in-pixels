extends Node

var chunk_items: Dictionary[Vector2i, Array] = {}

var world_item_scene := preload("res://entities/world_item.tscn")


func spawn_item_in_chunk(chunk: Vector2i, item_data, world_pos: Vector2, quantity: int = 1):
	var item = world_item_scene.instantiate()
	item.item_data = item_data
	item.quantity = quantity
	item.global_position = world_pos

	add_child(item)

	if !chunk_items.has(chunk):
		chunk_items[chunk] = []

	chunk_items[chunk].append(item)
	return item


func on_chunk_unloaded(chunk: Vector2i) -> void:
	if !chunk_items.has(chunk):
		return

	for item in chunk_items[chunk]:
		if is_instance_valid(item):
			item.queue_free()

	chunk_items.erase(chunk)


func get_nearby_items(origin: Vector2, radius: float) -> Array:
	var results: Array = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			if !chunk_items.has(key):
				continue

			for item in chunk_items[key]:
				if !is_instance_valid(item):
					continue

				var dx: float = item.global_position.x - origin.x
				var dy: float = item.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(item)

	return results
