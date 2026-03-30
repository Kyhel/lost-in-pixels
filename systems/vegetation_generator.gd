class_name VegetationGenerator
extends RefCounted

const TREE_1_ID := &"tree_1"
const TREE_2_ID := &"tree_2"

var _world_seed: int = 0
var _tree_generator: TreeGenerator

func _init(world_seed: int) -> void:
	_world_seed = world_seed
	_tree_generator = TreeGenerator.new(world_seed)


func generate_chunk_vegetation(chunk_coords: Vector2i, chunk: Chunk, chunk_size: int) -> void:

	if chunk == null:
		return

	if ConfigManager.config.spawn_trees:
		var placements: Array[Dictionary] = _tree_generator.generate_tree_placements_for_chunk(
			chunk_coords,
			chunk,
			chunk_size
		)
		for placement in placements:
			var world_tile: Vector2i = placement.get("world_tile", Vector2i.ZERO)
			var tree_type: TreeGenerator.TreeType = placement.get("tree_type", TreeGenerator.TreeType.TREE_1)
			_spawn_tree(world_tile, tree_type)

	if ConfigManager.config.spawn_small_vegetation:
		_spawn_small_vegetation(chunk_coords, chunk)


func get_nearby_trees(origin: Vector2, radius: float) -> Array[WorldObject]:
	var out: Array[WorldObject] = []
	for world_object in ObjectsManager.get_nearby_world_objects(origin, radius):
		if world_object.object_data == null:
			continue
		var id: StringName = world_object.object_data.id
		if id == TREE_1_ID or id == TREE_2_ID:
			out.append(world_object)
	return out


func _spawn_tree(tile_position: Vector2i, tree_type: TreeGenerator.TreeType) -> void:
	var object_id: StringName = TREE_1_ID
	if tree_type == TreeGenerator.TreeType.TREE_2:
		object_id = TREE_2_ID
	var tree_data: ObjectData = ObjectDatabase.get_object_data(object_id)
	_spawn_object_on_tile(tree_data, tile_position)


func _spawn_object_on_tile(object_data: ObjectData, world_tile: Vector2i) -> void:
	if object_data == null:
		return
	var world_pos: Vector2 = ChunkManager.world_tile_to_world_center(world_tile)
	var world_object: WorldObject = ObjectsManager.spawn_object_at(object_data, world_pos)
	if world_object == null:
		return
	var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk_node != null:
		var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
		chunk_node.register_environment_tile(local_tile)


func _spawn_small_vegetation(chunk_coords: Vector2i, chunk: Chunk) -> void:
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
			if _is_environment_tile_occupied(world_tile):
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

	var picked_placements: Array[Dictionary] = []
	for t: Vector2i in candidates:
		var defs: Variant = tile_to_defs.get(t, null)
		if defs == null:
			continue
		var def_list: Array = defs as Array
		if def_list.is_empty():
			continue
		var idx: int = rng.randi_range(0, def_list.size() - 1)
		var chosen: VegetationSpawnDefinition = def_list[idx] as VegetationSpawnDefinition
		if chosen == null:
			continue
		if _conflicts_with_picked(t, chosen, picked_placements):
			continue
		picked_placements.append({
			"tile": t,
			"definition": chosen
		})

	for placement in picked_placements:
		var world_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
		var chosen: VegetationSpawnDefinition = placement.get("definition", null) as VegetationSpawnDefinition
		if chosen == null:
			continue
		_spawn_object_on_tile(chosen.object_data, world_tile)


func _build_active_small_vegetation_definitions() -> Array[VegetationSpawnDefinition]:
	var out: Array[VegetationSpawnDefinition] = []
	for object_data in ConfigManager.config.small_vegetation:
		if object_data == null:
			continue
		var def: VegetationSpawnDefinition = VegetationDatabase.get_vegetation_spawn_definition(object_data.id)
		if def == null:
			push_warning("VegetationGenerator: no VegetationSpawnDefinition for ObjectData id '%s'; skipped." % String(object_data.id))
			continue
		if def.pass_type != VegetationSpawnDefinition.PassType.SMALL:
			continue
		out.append(def)
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

	if def.object_data == null:
		return false

	var d: float = clampf(def.density, 0.0, 1.0)
	if d <= 0.0:
		return false
	var salt := hash(def.object_data.id)
	var h: int = ChunkManager.get_chunk_seed(chunk_coords.x, chunk_coords.y) ^ hash(world_tile) ^ salt
	var roll_rng := RandomNumberGenerator.new()
	roll_rng.seed = h
	return roll_rng.randf() < d


func _chebyshev_tile(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _conflicts_with_picked(
	tile: Vector2i,
	definition: VegetationSpawnDefinition,
	picked_placements: Array[Dictionary]
) -> bool:
	var this_spacing: int = _spacing_for_definition(definition)
	for placement in picked_placements:
		var other_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
		var other_def: VegetationSpawnDefinition = placement.get("definition", null) as VegetationSpawnDefinition
		var required_spacing: int = maxi(this_spacing, _spacing_for_definition(other_def))
		if _chebyshev_tile(tile, other_tile) <= required_spacing:
			return true
	return false


func _spacing_for_definition(definition: VegetationSpawnDefinition) -> int:
	if definition == null:
		return 1
	return maxi(1, definition.min_spacing)


func _shuffle_vec2i_with_rng(arr: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _is_environment_tile_occupied(world_tile: Vector2i) -> bool:
	var chunk_coords: Vector2i = ChunkManager.world_tile_to_chunk_coords(world_tile)
	var chunk_node: Chunk = ChunkManager.get_loaded_chunk(chunk_coords)
	if chunk_node == null:
		return false
	var local_tile: Vector2i = ChunkManager.world_tile_to_local_tile(world_tile)
	return chunk_node.is_environment_tile_occupied(local_tile)
