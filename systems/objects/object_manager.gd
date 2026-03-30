extends Node

const FALLBACK_WORLD_OBJECT_RADIUS := 4.0
const PLACEMENT_MARGIN := 4.0
const OVERLAP_SEARCH_RADIUS := 64.0

var world_object_scene := preload("res://features/objects/scenes/base_world_object.tscn")


func clear_all_objects() -> void:
	pass

func update_chunks(_delta: float) -> void:
	pass

func spawn_object_in_chunk(chunk: Vector2i, object_data: ObjectData, world_pos: Vector2):
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk)
	if chunk_node == null:
		return null
	var target_container: Node2D = chunk_node.get_objects_container()
	if target_container == null:
		return null

	var world_object := _instantiate_world_object(object_data)
	if world_object == null:
		return null
	world_object.object_data = object_data

	target_container.add_child(world_object)
	world_object.global_position = world_pos
	_register_world_object_in_chunk(chunk_node, world_object)
	return world_object


func spawn_object_attached_in_chunk(
	chunk: Vector2i,
	object_data: ObjectData,
	parent: Node2D,
	local_pos: Vector2,
):
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk)
	if chunk_node == null:
		return null
	if parent == null or not is_instance_valid(parent):
		return null

	var world_object := _instantiate_world_object(object_data)
	if world_object == null:
		return null
	world_object.object_data = object_data
	parent.add_child(world_object)
	world_object.position = local_pos
	_register_world_object_in_chunk(chunk_node, world_object)
	return world_object


func spawn_object_at(object_data: ObjectData, world_pos: Vector2):
	var chunk: Vector2i = ChunkManager.world_pos_to_chunk_coords(world_pos)
	return spawn_object_in_chunk(chunk, object_data, world_pos)


func _instantiate_world_object(object_data: ObjectData) -> WorldObject:
	var object_scene: PackedScene = world_object_scene
	if object_data != null and object_data.scene != null:
		object_scene = object_data.scene
	var instance := object_scene.instantiate()
	if not (instance is WorldObject):
		push_warning("ObjectManager: scene '%s' root is not WorldObject." % object_scene.resource_path)
		if object_scene != world_object_scene:
			instance = world_object_scene.instantiate()
		else:
			return null
	return instance as WorldObject

func is_object_spawn_blocked(
	world_pos: Vector2,
	self_object_data: ObjectData,
	margin: float = PLACEMENT_MARGIN,
) -> bool:
	var self_radius: float = FALLBACK_WORLD_OBJECT_RADIUS
	if self_object_data != null:
		self_radius = self_object_data.hitbox_radius
	for wo in get_nearby_world_objects(world_pos, OVERLAP_SEARCH_RADIUS):
		var r: float = FALLBACK_WORLD_OBJECT_RADIUS
		if wo.object_data != null:
			r = wo.object_data.hitbox_radius
		else:
			r = Node2DUtils.get_collision_radius(wo)
			if r <= 0.0:
				r = FALLBACK_WORLD_OBJECT_RADIUS
		if world_pos.distance_to(wo.global_position) < self_radius + r + margin:
			return true
	return false

func _on_chunk_unloaded(_chunk: Vector2i, _chunk_node: Chunk) -> void:
	pass


func _on_world_reset() -> void:
	clear_all_objects()


func _register_world_object_in_chunk(chunk_node: Chunk, world_object: WorldObject) -> void:
	if chunk_node == null or world_object == null:
		return
	chunk_node.register_world_object(world_object)
	world_object.set_meta("chunk_coords", chunk_node.coords)
	var on_destroyed := Callable(self, "_on_world_object_destroyed").bind(world_object)
	if not world_object.destroyed.is_connected(on_destroyed):
		world_object.destroyed.connect(on_destroyed)
	var on_tree_exiting := Callable(self, "_on_world_object_tree_exiting").bind(world_object)
	if not world_object.tree_exiting.is_connected(on_tree_exiting):
		world_object.tree_exiting.connect(on_tree_exiting)


func _unregister_world_object(world_object: WorldObject) -> void:
	if world_object == null:
		return
	var chunk_meta: Variant = world_object.get_meta("chunk_coords", null)
	if chunk_meta == null or not chunk_meta is Vector2i:
		return
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_meta as Vector2i)
	if chunk_node == null:
		return
	chunk_node.unregister_world_object(world_object)


func _on_world_object_destroyed(_reason: String, world_object: WorldObject) -> void:
	_unregister_world_object(world_object)


func _on_world_object_tree_exiting(world_object: WorldObject) -> void:
	_unregister_world_object(world_object)

func get_nearby_world_objects(origin: Vector2, radius: float) -> Array[WorldObject]:
	var results: Array[WorldObject] = []
	var radius_sq := radius * radius
	var chunk_px := float(ChunkManager.CHUNK_SIZE * ChunkManager.TILE_SIZE)

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

			var key: Vector2i = Vector2i(cx, cy)
			var chunk: Chunk = ChunkManager.get_loaded_chunk(key)
			if chunk == null:
				continue
			for wo in chunk.get_world_objects():
				if wo == null or !is_instance_valid(wo):
					continue

				var dx: float = wo.global_position.x - origin.x
				var dy: float = wo.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(wo)

	return results
