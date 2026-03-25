extends Node2D

signal chunk_unloaded(chunk_coords: Vector2i, chunk: Chunk)

const TILE_SIZE = 16
const TILE_HALF_SIZE = TILE_SIZE / 2.0
const TILE_HALF_SIZE_VECTOR = Vector2.ONE * TILE_HALF_SIZE
const CHUNK_SIZE = 32
const CHUNK_AREA = CHUNK_SIZE * CHUNK_SIZE

const TERRAIN_VISION_RADIUS = 20

var loaded_chunks: Dictionary[Vector2i, Node] = {}

var chunk_scene = preload("res://features/world/chunk.tscn")
var world_generator: WorldGenerator
var tree_generator: TreeGenerator
var berry_bush_generator: Variant
var water_lily_generator: Variant
var fog_memory: Dictionary[Vector2i, Array] = {}


func _ready() -> void:
	_apply_world_seed(GameSession.get_active_world_seed())


func _apply_world_seed(p_seed: int) -> void:
	world_generator = WorldGenerator.new()
	world_generator.setup_seed(p_seed)
	var wseed: int = world_generator.terrain_noise.seed
	tree_generator = TreeGenerator.new(wseed)
	berry_bush_generator = load("res://features/world/nature/berry_bush_generator.gd").new(wseed)
	water_lily_generator = load("res://features/world/nature/water_lily_generator.gd").new(wseed)


func set_world_seed(p_seed: int) -> void:
	GameSession.set_active_world_seed(p_seed)
	_apply_world_seed(p_seed)


func get_world_seed() -> int:
	if world_generator == null:
		return 0
	return world_generator.terrain_noise.seed


func reset_world_state() -> void:
	for key in loaded_chunks.keys():
		var ch: Node = loaded_chunks[key]
		if is_instance_valid(ch):
			ch.queue_free()
	loaded_chunks.clear()
	fog_memory.clear()


func _on_world_reset() -> void:
	reset_world_state()


func _emit_chunk_unloaded(chunk_coords: Vector2i, chunk_node: Node) -> void:
	var chunk: Chunk = null
	if is_instance_valid(chunk_node) and chunk_node is Chunk:
		chunk = chunk_node as Chunk
	chunk_unloaded.emit(chunk_coords, chunk)


func merge_fog_from_save(entries: Array) -> void:
	for e in entries:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var cx: int = int(e.get("cx", 0))
		var cy: int = int(e.get("cy", 0))
		var grid = e.get("grid", null)
		if grid == null:
			continue
		fog_memory[Vector2i(cx, cy)] = grid as Array


func build_fog_save_payload() -> Array:
	var merged: Dictionary = {}
	for k in fog_memory.keys():
		merged[k] = fog_memory[k]
	for k in loaded_chunks.keys():
		var ch: Node = loaded_chunks[k]
		if is_instance_valid(ch) and ch is Chunk:
			merged[k] = (ch as Chunk).fog_grid
	var out: Array = []
	for k in merged.keys():
		out.append({
			"cx": k.x,
			"cy": k.y,
			"grid": _duplicate_fog_grid(merged[k]),
		})
	return out


func _duplicate_fog_grid(grid: Variant) -> Array:
	var out: Array = []
	for row in grid as Array:
		var row_arr: Array = []
		for cell in row as Array:
			row_arr.append(cell)
		out.append(row_arr)
	return out


## R: full generation (terrain + vegetation + creatures) Chebyshev radius from player chunk.
func get_load_radius() -> int:
	return ConfigManager.config.chunk_load_radius


func get_full_generation_radius() -> int:
	return get_load_radius()


## R+1: terrain + vegetation; no creatures beyond this toward the outer shell.
func get_vegetation_stream_radius() -> int:
	return get_full_generation_radius() + 1


## R+2: stream terrain only for the outer ring (chunk still gets full terrain on create).
func get_terrain_only_stream_radius() -> int:
	return get_full_generation_radius() + 2


func get_unload_radius() -> int:
	return get_terrain_only_stream_radius() + 2

func get_loaded_chunk(chunk_coords: Vector2i) -> Chunk:
	var node: Node = loaded_chunks.get(chunk_coords, null)
	if node != null and is_instance_valid(node) and node is Chunk:
		return node as Chunk
	return null


func _generate_chunk_terrain(chunk_x: int, chunk_y: int, chunk: Chunk) -> void:
	var tile_types: Array[WorldGenerator.TileType] = world_generator.compute_chunk_tile_types(
		chunk_x, chunk_y, CHUNK_SIZE
	)
	var ti := 0
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_type: WorldGenerator.TileType = tile_types[ti]
			ti += 1
			var biome: WorldGenerator.Biome = world_generator.biome_from_tile_type(tile_type)
			chunk.set_tile(x, y, world_generator.TILE_DEFS[tile_type]["atlas"])
			chunk.set_tile_type(x, y, tile_type)
			chunk.set_biome(x, y, biome)


func _generate_chunk_vegetation(chunk_x: int, chunk_y: int, chunk: Chunk) -> void:
	if ConfigManager.config.spawn_trees:
		tree_generator.generate_trees_for_chunk(
			Vector2i(chunk_x, chunk_y),
			chunk,
			CHUNK_SIZE)

	if ConfigManager.config.spawn_bushes:
		berry_bush_generator.generate_for_chunk(
			Vector2i(chunk_x, chunk_y), chunk)

	if ConfigManager.config.spawn_water_lilies:
		water_lily_generator.generate_for_chunk(
			Vector2i(chunk_x, chunk_y), chunk)

	chunk.vegetation_generated = true


func _create_chunk_with_terrain(chunk_x: int, chunk_y: int) -> void:
	var key: Vector2i = Vector2i(chunk_x, chunk_y)
	if loaded_chunks.has(key):
		return

	var chunk: Chunk = chunk_scene.instantiate() as Chunk
	chunk.coords = key
	add_child(chunk)
	chunk.position = Vector2i(
		chunk_x * CHUNK_SIZE * TILE_SIZE,
		chunk_y * CHUNK_SIZE * TILE_SIZE
	)
	loaded_chunks[key] = chunk
	chunk.init_fog(fog_memory.get(key, null))
	_generate_chunk_terrain(chunk_x, chunk_y, chunk)


func _spawn_chunk_creatures(chunk: Chunk, key: Vector2i) -> void:
	CreatureManager.spawn_entities(chunk, key)
	chunk.creatures_generated = true


func _chebyshev_to_player_chunk(player_chunk: Vector2i, key: Vector2i) -> int:
	return maxi(abs(key.x - player_chunk.x), abs(key.y - player_chunk.y))


func _pick_closest_chunk_key(candidates: Array[Vector2i], player_chunk: Vector2i) -> Vector2i:
	var best: Vector2i = candidates[0]
	var best_d: int = _chebyshev_to_player_chunk(player_chunk, best)
	for i in range(1, candidates.size()):
		var k: Vector2i = candidates[i]
		var d: int = _chebyshev_to_player_chunk(player_chunk, k)
		if d < best_d or (d == best_d and (k.x < best.x or (k.x == best.x and k.y < best.y))):
			best = k
			best_d = d
	return best


func _vegetation_neighbours_ready(key: Vector2i, required: Dictionary) -> bool:
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var nk: Vector2i = Vector2i(key.x + dx, key.y + dy)
			if not required.has(nk):
				return false
			if not loaded_chunks.has(nk):
				return false
	return true


func _build_required_chunks(player_chunk: Vector2i, stream_radius: int) -> Dictionary:
	var required: Dictionary = {}
	for x in range(player_chunk.x - stream_radius, player_chunk.x + stream_radius + 1):
		for y in range(player_chunk.y - stream_radius, player_chunk.y + stream_radius + 1):
			required[Vector2i(x, y)] = true
	return required


func update_chunks(player_pos: Vector2) -> void:
	var player_chunk: Vector2i = world_pos_to_chunk_coords(player_pos)
	var stream_r: int = get_terrain_only_stream_radius()
	var required: Dictionary = _build_required_chunks(player_chunk, stream_r)
	var full_r: int = get_full_generation_radius()
	var veg_r: int = get_vegetation_stream_radius()

	var creature_candidates: Array[Vector2i] = []
	var veg_candidates: Array[Vector2i] = []
	var missing_chunks: Array[Vector2i] = []

	for key: Vector2i in required.keys():
		if not loaded_chunks.has(key):
			missing_chunks.append(key)
			continue
		var ch: Node = loaded_chunks[key]
		if not is_instance_valid(ch) or not (ch is Chunk):
			continue
		var chunk: Chunk = ch as Chunk
		var d: int = _chebyshev_to_player_chunk(player_chunk, key)

		if d <= full_r and chunk.vegetation_generated and not chunk.creatures_generated:
			creature_candidates.append(key)

		if d <= veg_r and not chunk.vegetation_generated and _vegetation_neighbours_ready(key, required):
			veg_candidates.append(key)

	if not creature_candidates.is_empty():
		var pick: Vector2i = _pick_closest_chunk_key(creature_candidates, player_chunk)
		_spawn_chunk_creatures(loaded_chunks[pick] as Chunk, pick)
	elif not veg_candidates.is_empty():
		var pick2: Vector2i = _pick_closest_chunk_key(veg_candidates, player_chunk)
		var c2: Chunk = loaded_chunks[pick2] as Chunk
		_generate_chunk_vegetation(pick2.x, pick2.y, c2)
	elif not missing_chunks.is_empty():
		var pick3: Vector2i = _pick_closest_chunk_key(missing_chunks, player_chunk)
		_create_chunk_with_terrain(pick3.x, pick3.y)

	unload_far_chunks(player_pos)


func unload_far_chunks(player_pos: Vector2) -> void:
	var player_chunk = world_pos_to_chunk_coords(player_pos)

	for key in loaded_chunks.keys():
		var dx = abs(key.x - player_chunk.x)
		var dy = abs(key.y - player_chunk.y)

		if dx > get_unload_radius() or dy > get_unload_radius():
			var chunk: Node = loaded_chunks[key]
			_emit_chunk_unloaded(key, chunk)
			if chunk is Chunk:
				fog_memory[key] = (chunk as Chunk).fog_grid
			chunk.queue_free()  # supprime du tree
			loaded_chunks.erase(key)

func get_walk_speed_at_world_pos(world_pos: Vector2) -> float:
	var def := get_tile_def_from_world_pos(world_pos)
	return def.get("walk_speed", 1.0)

func can_creature_moveat_tile(creature: Creature, world_pos: Vector2) -> bool:
	var def := get_tile_def_from_world_pos(world_pos)

	var can_walk = def.get("walkable", false)
	var can_swim = def.get("swimmable", false) and creature.creature_data.can_swim

	return can_walk or can_swim

## Returns true if every tile within [size_pixels] of [center] is walkable (uses [method is_walkable] per tile).
func is_area_walkable_for_creature(creature: Creature, center: Vector2, size_pixels: float) -> bool:
	if size_pixels <= 0.0:
		return can_creature_moveat_tile(creature, center)
	var radius := size_pixels
	var base_tile := world_pos_to_world_tile(center)
	var tile_radius := ceili(radius / TILE_SIZE)
	for dx in range(-tile_radius, tile_radius + 1):
		for dy in range(-tile_radius, tile_radius + 1):
			var tile_coords := Vector2i(base_tile.x + dx, base_tile.y + dy)
			var tile_center := Vector2(
				(tile_coords.x + 0.5) * TILE_SIZE,
				(tile_coords.y + 0.5) * TILE_SIZE
			)
			if center.distance_to(tile_center) > radius:
				continue
			if not can_creature_moveat_tile(creature, tile_center):
				return false
	return true

## Returns true if [creature] would collide with any environment collider when centered at [world_pos].
func is_environment_blocking_creature(creature: Creature, world_pos: Vector2) -> bool:
	if creature == null:
		return false
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return false
	if creature.collisionShape == null or creature.collisionShape.shape == null:
		return false

	var shape_node: CollisionShape2D = creature.collisionShape
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.collision_mask = Layers.ENVIRONMENT
	params.collide_with_bodies = true
	params.collide_with_areas = false

	# Reuse the creature's collision shape and place it at the tested world position.
	var base_xform: Transform2D = shape_node.global_transform
	params.transform = Transform2D(base_xform.x, base_xform.y, world_pos)

	var results: Array = space.intersect_shape(params, 1)
	return not results.is_empty()

func reveal_around_player(player_pos):

	var tile_pos: Vector2i = world_pos_to_world_tile(player_pos)

	var radius = TERRAIN_VISION_RADIUS

	for x in range(-radius,radius+1):
		for y in range(-radius,radius+1):

			if x*x + y*y <= radius*radius:

				var world_x = tile_pos.x + x
				var world_y = tile_pos.y + y

				reveal_tile(world_x,world_y)

func get_tile_def_from_world_pos(world_pos: Vector2) -> Dictionary:
	# 1) convert from pixels to world tile coords
	var world_tile_coords: Vector2i = world_pos_to_world_tile(world_pos)

	var chunk_coords: Vector2i = world_pos_to_chunk_coords(world_pos)

	if !loaded_chunks.has(chunk_coords):
		return {}  # or some safe default
	var chunk := loaded_chunks[chunk_coords]
	# 3) local tile coordinates inside the chunk
	var local: Vector2i = world_tile_to_local_tile(world_tile_coords)
	# 4) return the stored def (atlas, walk_speed, walkable, …)
	return world_generator.TILE_DEFS[chunk.get_tile_type(local.x, local.y)]

## Tile type at a world pixel position using loaded chunk data (same coordinate path as [method get_tile_def_from_world_pos]).
func get_tile_type_at_world_pos(world_pos: Vector2) -> WorldGenerator.TileType:
	var world_tile_coords: Vector2i = world_pos_to_world_tile(world_pos)
	var chunk_coords: Vector2i = world_pos_to_chunk_coords(world_pos)
	if not loaded_chunks.has(chunk_coords):
		return WorldGenerator.TileType.NONE
	var chunk: Chunk = loaded_chunks[chunk_coords] as Chunk
	if not is_instance_valid(chunk):
		return WorldGenerator.TileType.NONE
	var local: Vector2i = world_tile_to_local_tile(world_tile_coords)
	return chunk.get_tile_type(local.x, local.y)

func reveal_tile(world_x, world_y):

	var world_tile: Vector2i = Vector2i(world_x, world_y)
	var key: Vector2i = world_tile_to_chunk_coords(world_tile)

	if !loaded_chunks.has(key):
		return
	var chunk = loaded_chunks[key]

	var local_tile: Vector2i = world_tile_to_local_tile(world_tile)

	chunk.reveal(local_tile.x, local_tile.y)

func get_chunk_seed(chunk_x:int, chunk_y:int) -> int:
	return world_generator.terrain_noise.seed ^ (chunk_x * 73856093) ^ (chunk_y * 19349663)

func world_pos_to_world_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / float(TILE_SIZE))),
		int(floor(world_pos.y / float(TILE_SIZE)))
	)

func world_tile_to_world_pos(world_tile: Vector2i) -> Vector2:
	return world_tile * TILE_SIZE

func world_tile_to_world_center(world_tile: Vector2i) -> Vector2:
	return world_tile_to_world_pos(world_tile) + TILE_HALF_SIZE_VECTOR

func world_pos_to_chunk_coords(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / float(CHUNK_SIZE * TILE_SIZE))),
		int(floor(pos.y / float(CHUNK_SIZE * TILE_SIZE)))
	)

func world_tile_to_chunk_coords(world_tile: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(world_tile.x / float(CHUNK_SIZE))),
		int(floor(world_tile.y / float(CHUNK_SIZE)))
	)

func world_tile_to_local_tile(world_tile: Vector2i) -> Vector2i:
	return Vector2i(
		posmod(world_tile.x, CHUNK_SIZE),
		posmod(world_tile.y, CHUNK_SIZE)
	)

## Vegetation generation only: loaded chunk tile data, no world generator fallback.
func get_tile_type_for_generation(world_x: int, world_y: int) -> WorldGenerator.TileType:
	var world_tile := Vector2i(world_x, world_y)
	var key := world_tile_to_chunk_coords(world_tile)
	if not loaded_chunks.has(key):
		push_error("ChunkManager.get_tile_type_for_generation: chunk not loaded %s" % str(key))
		return WorldGenerator.TileType.NONE
	var ch: Node = loaded_chunks[key]
	if not is_instance_valid(ch) or not (ch is Chunk):
		return WorldGenerator.TileType.WATER
	var local_tile := world_tile_to_local_tile(world_tile)
	return (ch as Chunk).get_tile_type(local_tile.x, local_tile.y)
