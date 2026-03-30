extends Node

const MIN_PICKED_TILE_CHEBYSHEV := 3
const BERRY_BUSH_ID := &"berry_bush"
const WATER_LILY_ID := &"water_lily"

var occlusion_mask_viewport: SubViewport

var tree_1_data: ObjectData = preload("res://features/objects/data/trees/tree_1.tres")
var tree_2_data: ObjectData = preload("res://features/objects/data/trees/tree_2.tres")

func refresh_scene_references() -> void:
	var scene := get_tree().current_scene
	if scene:
		occlusion_mask_viewport = scene.find_child("AlphaMaskViewport", true, false) as SubViewport


func clear_all_vegetation() -> void:
	pass


func update_chunks(_delta: float) -> void:
	pass


func spawn_tree(tile_position: Vector2i, tree_type: TreeGenerator.TreeType) -> void:
	if occlusion_mask_viewport == null or not is_instance_valid(occlusion_mask_viewport):
		refresh_scene_references()
	var tree_data: ObjectData = get_tree_object_data(tree_type)
	if tree_data == null:
		return
	var tree_pos: Vector2 = ChunkManager.world_tile_to_world_center(tile_position)
	var tree: WorldObject = ObjectsManager.spawn_object_at(tree_data, tree_pos)
	if tree == null:
		return
	var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(tile_position)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk_node != null:
		var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(tile_position)
		chunk_node.register_environment_tile(local_tile)
	var foliage := tree.get_node_or_null("Foliage") as Sprite2D
	var foliage_material := foliage.material if foliage != null else null
	if occlusion_mask_viewport != null:
		if foliage_material is ShaderMaterial:
			(foliage_material as ShaderMaterial).set_shader_parameter("mask_tex", occlusion_mask_viewport.get_texture())
	else:
		push_warning("VegetationManager: AlphaMaskViewport missing; tree spawned without mask.")


func get_tree_object_data(tree_type: TreeGenerator.TreeType) -> ObjectData:
	match tree_type:
		TreeGenerator.TreeType.TREE_1:
			return tree_1_data
		TreeGenerator.TreeType.TREE_2:
			return tree_2_data
		_:
			return tree_1_data


func spawn_vegetation(
	world_tile: Vector2i,
	vegetation_scene: PackedScene,
	features: Array[Resource] = [],
) -> Vegetation:
	var resolved_chunk: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(resolved_chunk)
	if chunk_node == null:
		return null
	var target_container: Node2D = chunk_node.get_vegetation_container()
	if target_container == null:
		return null

	var vegetation: Vegetation = vegetation_scene.instantiate() as Vegetation
	if vegetation == null:
		return null
	if not features.is_empty():
		vegetation.features = features
	vegetation.chunk_coords = resolved_chunk
	vegetation.world_tile = world_tile
	target_container.add_child(vegetation)
	# Set global position only after parenting to avoid chunk transform offset.
	vegetation.global_position = ChunkManager.world_tile_to_world_center(world_tile)
	var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
	chunk_node.register_environment_tile(local_tile)
	return vegetation as Vegetation


func spawn_berry_bush(world_tile: Vector2i) -> void:
	var def: VegetationSpawnDefinition = VegetationDatabase.get_vegetation_spawn_definition(BERRY_BUSH_ID)
	if def == null or def.scene == null:
		return
	spawn_vegetation(world_tile, def.scene)


func spawn_water_lily(world_tile: Vector2i) -> void:
	var def: VegetationSpawnDefinition = VegetationDatabase.get_vegetation_spawn_definition(WATER_LILY_ID)
	if def == null or def.scene == null:
		return
	spawn_vegetation(world_tile, def.scene)


func spawn_small_vegetation(chunk_coords: Vector2i, chunk: Chunk) -> void:
	var active_defs: Array[VegetationSpawnDefinition] = _build_active_small_vegetation_definitions()
	if active_defs.is_empty():
		return

	var tile_to_defs: Dictionary = {}
	var chunk_size: int = ChunkManager.CHUNK_SIZE

	for local_x in range(chunk_size):
		for local_y in range(chunk_size):
			var local_tile: Vector2i = Vector2i(local_x, local_y)
			var world_tile: Vector2i = Vector2i(
				chunk_coords.x * chunk_size + local_x,
				chunk_coords.y * chunk_size + local_y
			)
			if is_environment_tile_occupied(world_tile):
				continue
			var valid: Array[VegetationSpawnDefinition] = []
			for def in active_defs:
				if not _definition_passes_static_rules(def, local_tile, chunk):
					continue
				if not _definition_passes_density(def, world_tile, chunk_coords):
					continue
				valid.append(def)
			if not valid.is_empty():
				tile_to_defs[world_tile] = valid

	if tile_to_defs.is_empty():
		return

	var candidates: Array[Vector2i] = []
	for k in tile_to_defs.keys():
		candidates.append(k as Vector2i)

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_chunk_seed(chunk_coords.x, chunk_coords.y)
	_shuffle_vec2i_with_rng(candidates, rng)

	var picked: Array[Vector2i] = []
	for t: Vector2i in candidates:
		if _conflicts_with_picked(t, picked, MIN_PICKED_TILE_CHEBYSHEV):
			continue
		picked.append(t)

	for world_tile: Vector2i in picked:
		var defs: Variant = tile_to_defs.get(world_tile, null)
		if defs == null:
			continue
		var def_list: Array = defs as Array
		if def_list.is_empty():
			continue
		var idx: int = rng.randi_range(0, def_list.size() - 1)
		var chosen: VegetationSpawnDefinition = def_list[idx] as VegetationSpawnDefinition
		if chosen != null and chosen.scene != null:
			spawn_vegetation(world_tile, chosen.scene)


func _build_active_small_vegetation_definitions() -> Array[VegetationSpawnDefinition]:
	var out: Array[VegetationSpawnDefinition] = []
	if ConfigManager.config.spawn_bushes:
		var b: VegetationSpawnDefinition = VegetationDatabase.get_vegetation_spawn_definition(BERRY_BUSH_ID)
		if b != null and b.pass_type == VegetationSpawnDefinition.PassType.SMALL:
			out.append(b)
	if ConfigManager.config.spawn_water_lilies:
		var w: VegetationSpawnDefinition = VegetationDatabase.get_vegetation_spawn_definition(WATER_LILY_ID)
		if w != null and w.pass_type == VegetationSpawnDefinition.PassType.SMALL:
			out.append(w)
	return out


func _definition_passes_static_rules(
	def: VegetationSpawnDefinition,
	local_tile: Vector2i,
	chunk: Chunk
) -> bool:
	var rules: Array = def.static_spawn_rules
	if rules == null:
		return true
	for rule in rules:
		if rule == null:
			return false
		if not rule.is_valid(local_tile, chunk):
			return false
	return true


func _definition_passes_density(
	def: VegetationSpawnDefinition,
	world_tile: Vector2i,
	chunk_coords: Vector2i
) -> bool:
	var d: float = clampf(def.density, 0.0, 1.0)
	if d <= 0.0:
		return false
	var salt: int
	var path: String = def.resource_path
	if path.is_empty():
		salt = hash(def.scene.resource_path) if def.scene else 0
	else:
		salt = hash(path)
	var h: int = ChunkManager.get_chunk_seed(chunk_coords.x, chunk_coords.y) ^ hash(world_tile) ^ salt
	var roll_rng := RandomNumberGenerator.new()
	roll_rng.seed = h
	return roll_rng.randf() < d


func _chebyshev_tile(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _conflicts_with_picked(tile: Vector2i, picked: Array[Vector2i], min_spacing: int) -> bool:
	for p: Vector2i in picked:
		if _chebyshev_tile(tile, p) < min_spacing:
			return true
	return false


func _shuffle_vec2i_with_rng(arr: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func is_environment_tile_occupied(world_tile: Vector2i) -> bool:
	var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk_node == null:
		return false
	var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
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


func _on_world_reset() -> void:
	clear_all_vegetation()


func get_nearby_vegetation(origin: Vector2, radius: float) -> Array[Vegetation]:
	var results: Array[Vegetation] = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.world_pos_to_chunk_coords(origin)

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


func get_nearby_trees(origin: Vector2, radius: float) -> Array[WorldObject]:
	var out: Array[WorldObject] = []
	for world_object in ObjectsManager.get_nearby_world_objects(origin, radius):
		if world_object.object_data == null:
			continue
		var id: StringName = world_object.object_data.id
		if id == &"tree_1" or id == &"tree_2":
			out.append(world_object)
	return out
