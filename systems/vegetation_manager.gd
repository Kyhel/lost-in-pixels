extends Node

var occlusion_mask_viewport: SubViewport

var tree_1_scene := preload("res://features/world/nature/trees/tree_1.tscn")
var tree_2_scene := preload("res://features/world/nature/trees/tree_2.tscn")
var berry_bush_scene := preload("res://features/world/nature/berry_bush.tscn")
var water_lily_scene := preload("res://features/world/nature/water_lily.tscn")

func refresh_scene_references() -> void:
	var scene := get_tree().current_scene
	if scene:
		occlusion_mask_viewport = scene.find_child("AlphaMaskViewport", true, false) as SubViewport


func clear_all_vegetation() -> void:
	pass


func update_chunks(_delta: float) -> void:
	pass


func spawn_tree(chunk: Vector2i, tile_position: Vector2i, tree_type: TreeGenerator.TreeType) -> void:
	if occlusion_mask_viewport == null or not is_instance_valid(occlusion_mask_viewport):
		refresh_scene_references()

	var tree := spawn_vegetation(chunk, tile_position, get_tree_scene(tree_type))
	if tree == null:
		return
	var foliage_material = tree.get_node("Foliage").material
	if occlusion_mask_viewport != null:
		foliage_material.set_shader_parameter("mask_tex", occlusion_mask_viewport.get_texture())
	else:
		push_warning("VegetationManager: AlphaMaskViewport missing; tree spawned without mask.")


func get_tree_scene(tree_type: TreeGenerator.TreeType) -> PackedScene:
	match tree_type:
		TreeGenerator.TreeType.TREE_1:
			return tree_1_scene
		TreeGenerator.TreeType.TREE_2:
			return tree_2_scene
		_:
			return tree_1_scene


func spawn_vegetation(chunk: Vector2i, world_tile: Vector2i, vegetation_scene: PackedScene) -> Vegetation:
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk)
	if chunk_node == null:
		return null
	var target_container: Node2D = chunk_node.get_vegetation_container()
	if target_container == null:
		return null

	var vegetation: Node2D = vegetation_scene.instantiate() as Node2D
	vegetation.set("chunk_coords", chunk)
	vegetation.set("world_tile", world_tile)
	vegetation.global_position = Vector2(
		world_tile.x * ChunkManager.TILE_SIZE + ChunkManager.TILE_HALF_SIZE,
		world_tile.y * ChunkManager.TILE_SIZE + ChunkManager.TILE_HALF_SIZE
	)
	target_container.add_child(vegetation)
	vegetation.global_position = Vector2(
		world_tile.x * ChunkManager.TILE_SIZE + ChunkManager.TILE_HALF_SIZE,
		world_tile.y * ChunkManager.TILE_SIZE + ChunkManager.TILE_HALF_SIZE
	)
	var local_tile: Vector2i = Vector2i(
		world_tile.x - chunk.x * ChunkManager.CHUNK_SIZE,
		world_tile.y - chunk.y * ChunkManager.CHUNK_SIZE
	)
	chunk_node.register_environment_tile(local_tile)
	return vegetation as Vegetation


func spawn_berry_bush(chunk: Vector2i, world_tile: Vector2i) -> void:
	spawn_vegetation(chunk, world_tile, berry_bush_scene)


func spawn_water_lily(chunk: Vector2i, world_tile: Vector2i) -> void:
	spawn_vegetation(chunk, world_tile, water_lily_scene)


func is_environment_tile_occupied(world_tile: Vector2i) -> bool:
	var chunk_coords := Vector2i(
		int(floor(float(world_tile.x) / float(ChunkManager.CHUNK_SIZE))),
		int(floor(float(world_tile.y) / float(ChunkManager.CHUNK_SIZE)))
	)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk_node == null:
		return false
	var local_tile: Vector2i = Vector2i(
		world_tile.x - chunk_coords.x * ChunkManager.CHUNK_SIZE,
		world_tile.y - chunk_coords.y * ChunkManager.CHUNK_SIZE
	)
	return chunk_node.is_environment_tile_occupied(local_tile)


func vegetation_blocks_point(world_pos: Vector2, self_radius: float, margin: float, node: Vegetation) -> bool:
	var r: Variant = node.get("hitbox_radius")
	var c: Variant = node.get("hitbox_center_world")
	if r == null or c == null:
		return false
	if not (r is float or r is int):
		return false
	if not c is Vector2:
		return false
	var rf: float = float(r)
	if rf <= 0.0:
		return false
	return world_pos.distance_to(c as Vector2) < self_radius + rf + margin


func _on_chunk_unloaded(_chunk: Vector2i, _chunk_node: Chunk) -> void:
	pass


func _on_world_reset(_clear_fog_memory: bool) -> void:
	clear_all_vegetation()


func get_nearby_vegetation(origin: Vector2, radius: float) -> Array[Vegetation]:
	var results: Array[Vegetation] = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			var chunk: Chunk = ChunkManager.get_loaded_chunk(key)
			if chunk == null:
				continue
			var vegetation_container: Node2D = chunk.get_vegetation_container()
			if vegetation_container == null:
				continue

			for veg_node in vegetation_container.get_children():
				var veg: Vegetation = veg_node as Vegetation
				if veg == null or not is_instance_valid(veg):
					continue

				var dx: float = veg.global_position.x - origin.x
				var dy: float = veg.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(veg)

	return results


func get_nearby_trees(origin: Vector2, radius: float) -> Array[Vegetation]:
	var out: Array[Vegetation] = []
	for veg in get_nearby_vegetation(origin, radius):
		if veg.is_tree():
			out.append(veg)
	return out
