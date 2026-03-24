extends Node

const FALLBACK_WORLD_ITEM_RADIUS := 4.0
const PLACEMENT_MARGIN := 4.0
const OVERLAP_SEARCH_RADIUS := 64.0

var world_item_scene := preload("res://data/objects/world_item.tscn")


func clear_all_objects() -> void:
	pass

func update_chunks(_delta: float) -> void:
	pass

func spawn_item_in_chunk(chunk: Vector2i, item_data, world_pos: Vector2, quantity: int = 1):
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk)
	if chunk_node == null:
		return null
	var target_container: Node2D = chunk_node.get_objects_container()
	if target_container == null:
		return null

	var item = world_item_scene.instantiate()
	item.item_data = item_data
	item.quantity = quantity
	item.global_position = world_pos

	target_container.add_child(item)
	item.global_position = world_pos
	return item


func spawn_item_at(item_data, world_pos: Vector2, quantity: int = 1):
	var chunk: Vector2i = ChunkManager.get_chunk_from_position(world_pos)
	return spawn_item_in_chunk(chunk, item_data, world_pos, quantity)

func is_item_spawn_blocked(
	world_pos: Vector2,
	self_item_data: ItemData,
	margin: float = PLACEMENT_MARGIN,
) -> bool:
	var self_radius: float = FALLBACK_WORLD_ITEM_RADIUS
	if self_item_data != null:
		self_radius = self_item_data.hitbox_radius
	for item in get_nearby_items(world_pos, OVERLAP_SEARCH_RADIUS):
		var r: float = FALLBACK_WORLD_ITEM_RADIUS
		if item.item_data != null:
			r = item.item_data.hitbox_radius
		else:
			r = Node2DUtils.get_collision_radius(item)
			if r <= 0.0:
				r = FALLBACK_WORLD_ITEM_RADIUS
		if world_pos.distance_to(item.global_position) < self_radius + r + margin:
			return true
	for veg in VegetationManager.get_nearby_vegetation(world_pos, OVERLAP_SEARCH_RADIUS):
		if VegetationManager.vegetation_blocks_point(world_pos, self_radius, margin, veg):
			return true
	return false

func _on_chunk_unloaded(_chunk: Vector2i, _chunk_node: Chunk) -> void:
	pass


func _on_world_reset(_clear_fog_memory: bool) -> void:
	clear_all_objects()

func get_nearby_items(origin: Vector2, radius: float) -> Array[WorldItem]:
	var results: Array[WorldItem] = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			var chunk: Chunk = ChunkManager.get_loaded_chunk(key)
			if chunk == null:
				continue
			var objects_container: Node2D = chunk.get_objects_container()
			if objects_container == null:
				continue
			for item_node in objects_container.get_children():
				var item: WorldItem = item_node as WorldItem
				if item == null or !is_instance_valid(item):
					continue

				var dx: float = item.global_position.x - origin.x
				var dy: float = item.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(item)

	return results
