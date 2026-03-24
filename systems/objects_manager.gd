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

	target_container.add_child(item)
	item.global_position = world_pos
	_register_item_in_chunk(chunk_node, item)
	return item


func spawn_item_attached_in_chunk(
	chunk: Vector2i,
	item_data,
	parent: Node2D,
	local_pos: Vector2,
	quantity: int = 1
):
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk)
	if chunk_node == null:
		return null
	if parent == null or not is_instance_valid(parent):
		return null

	var item = world_item_scene.instantiate()
	item.item_data = item_data
	item.quantity = quantity
	parent.add_child(item)
	item.position = local_pos
	_register_item_in_chunk(chunk_node, item)
	return item


func spawn_item_at(item_data: ItemData, world_pos: Vector2, quantity: int = 1):
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


func _register_item_in_chunk(chunk_node: Chunk, item: WorldItem) -> void:
	if chunk_node == null or item == null:
		return
	chunk_node.register_world_item(item)
	item.set_meta("chunk_coords", chunk_node.coords)
	var on_destroyed := Callable(self, "_on_item_destroyed").bind(item)
	if not item.destroyed.is_connected(on_destroyed):
		item.destroyed.connect(on_destroyed)
	var on_tree_exiting := Callable(self, "_on_item_tree_exiting").bind(item)
	if not item.tree_exiting.is_connected(on_tree_exiting):
		item.tree_exiting.connect(on_tree_exiting)


func _unregister_item(item: WorldItem) -> void:
	if item == null:
		return
	var chunk_meta: Variant = item.get_meta("chunk_coords", null)
	if chunk_meta == null or not chunk_meta is Vector2i:
		return
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_meta as Vector2i)
	if chunk_node == null:
		return
	chunk_node.unregister_world_item(item)


func _on_item_destroyed(_reason: String, item: WorldItem) -> void:
	_unregister_item(item)


func _on_item_tree_exiting(item: WorldItem) -> void:
	_unregister_item(item)

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
			for item in chunk.get_world_items():
				if item == null or !is_instance_valid(item):
					continue

				var dx: float = item.global_position.x - origin.x
				var dy: float = item.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(item)

	return results
