extends Node2D

const TILE_SIZE = 16
const CHUNK_SIZE = 32
const CHUNK_AREA = CHUNK_SIZE * CHUNK_SIZE

const TERRAIN_VISION_RADIUS = 20
const MONSTER_VISION_RADIUS = 200

var loaded_chunks: Dictionary[Vector2i, Node] = {}

var chunk_scene = preload("res://world/chunk.tscn")
var world_generator: WorldGenerator
var tree_generator: TreeGenerator
var fog_memory: Dictionary[Vector2i, Array] = {}


func _ready() -> void:
	_apply_world_seed(GameSession.get_active_world_seed())


func _apply_world_seed(p_seed: int) -> void:
	world_generator = preload("res://world/world_generator.gd").new()
	world_generator.setup_seed(p_seed)
	tree_generator = TreeGenerator.new(world_generator.terrain_noise.seed)


func set_world_seed(p_seed: int) -> void:
	GameSession.set_active_world_seed(p_seed)
	_apply_world_seed(p_seed)


func get_world_seed() -> int:
	if world_generator == null:
		return 0
	return world_generator.terrain_noise.seed


func reset_world_state(clear_fog_memory: bool = true) -> void:
	for key in loaded_chunks.keys():
		var ch = loaded_chunks[key]
		if is_instance_valid(ch):
			ch.queue_free()
	loaded_chunks.clear()
	if clear_fog_memory:
		fog_memory.clear()


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

func get_load_radius() -> int:
	return DebugManager.debug_config.chunk_load_radius

func get_unload_radius() -> int:
	return get_load_radius() + 4

func load_chunk(chunk_x, chunk_y):

	var key: Vector2i = Vector2i(chunk_x, chunk_y)

	if loaded_chunks.has(key):
		return

	# print("loading chunk ", key)

	var chunk = chunk_scene.instantiate()
	chunk.coords = key

	add_child(chunk)

	chunk.position = Vector2i(
		chunk_x * CHUNK_SIZE * TILE_SIZE,
		chunk_y * CHUNK_SIZE * TILE_SIZE
	)

	loaded_chunks[key] = chunk

	chunk.init_fog(fog_memory.get(key, null))

	generate_chunk(chunk_x, chunk_y, chunk)

	EntitiesManager.spawn_entities(chunk, key)

func generate_chunk(chunk_x, chunk_y, chunk: Chunk):

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):

			var world_x = chunk_x * CHUNK_SIZE + x
			var world_y = chunk_y * CHUNK_SIZE + y

			var tile_type = world_generator.get_tile_type(world_x, world_y)
			var biome = world_generator.get_biome(world_x, world_y)

			chunk.set_tile(x,y,world_generator.TILE_DEFS[tile_type]["atlas"])
			chunk.set_tile_type(x, y, tile_type)
			chunk.set_biome(x, y, biome)

	# _spawn_world_items(chunk_x, chunk_y)

	tree_generator.generate_trees_for_chunk(
		Vector2i(chunk_x, chunk_y),
		chunk,
		CHUNK_SIZE,
		world_generator)

func _spawn_world_items(chunk_x: int, chunk_y: int):

	var rng := RandomNumberGenerator.new()
	rng.seed = get_chunk_seed(chunk_x, chunk_y) + 12345

	var item_count := rng.randi_range(0, 2)
	for i in range(item_count):
		var local_x: int = rng.randi_range(0, CHUNK_SIZE - 1)
		var local_y: int = rng.randi_range(0, CHUNK_SIZE - 1)

		var world_x: int = chunk_x * CHUNK_SIZE + local_x
		var world_y: int = chunk_y * CHUNK_SIZE + local_y

		var world_pos: Vector2 = Vector2(
			world_x * TILE_SIZE,
			world_y * TILE_SIZE
		)

		var chunk_key: Vector2i = Vector2i(chunk_x, chunk_y)
		var item_data = ItemDatabase.get_item(&"coin")
		if item_data:
			var centered := world_pos + Vector2.ONE * TILE_SIZE / 2.0
			ObjectsManager.spawn_item_in_chunk(chunk_key, item_data, centered)

func update_chunks(player_pos:Vector2):

	var chunk = get_chunk_from_position(player_pos)

	for x in range(chunk.x-get_load_radius(), chunk.x+get_load_radius()+1):
		for y in range(chunk.y-get_load_radius(), chunk.y+get_load_radius()+1):
			load_chunk(x,y)

	unload_far_chunks(player_pos)

func unload_far_chunks(player_pos:Vector2):

	var player_chunk = get_chunk_from_position(player_pos)

	for key in loaded_chunks.keys():
		var dx = abs(key.x - player_chunk.x)
		var dy = abs(key.y - player_chunk.y)

		if dx > get_unload_radius() or dy > get_unload_radius():
			var chunk = loaded_chunks[key]
			fog_memory[key] = chunk.fog_grid
			chunk.queue_free()  # supprime du tree
			loaded_chunks.erase(key)
			EntitiesManager.on_chunk_unloaded(key)
			ObjectsManager.on_chunk_unloaded(key)

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
	var base_tile := get_tile_coords_from_world_pos(center)
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

	var tile_pos = Vector2i(
		floor(player_pos.x / TILE_SIZE),
		floor(player_pos.y / TILE_SIZE)
	)

	var radius = TERRAIN_VISION_RADIUS

	for x in range(-radius,radius+1):
		for y in range(-radius,radius+1):

			if x*x + y*y <= radius*radius:

				var world_x = tile_pos.x + x
				var world_y = tile_pos.y + y

				reveal_tile(world_x,world_y)

func get_tile_def_from_world_pos(world_pos: Vector2) -> Dictionary:
	# 1) convert from pixels to world tile coords
	var world_tile_coords = get_tile_coords_from_world_pos(world_pos)

	var chunk_coords := get_chunk_from_position(world_pos)

	if !loaded_chunks.has(chunk_coords):
		return {}  # or some safe default
	var chunk := loaded_chunks[chunk_coords]
	# 3) local tile coordinates inside the chunk
	var local := get_tile_coords_relative_to_chunk(world_tile_coords)
	# 4) return the stored def (atlas, walk_speed, walkable, …)
	return world_generator.TILE_DEFS[chunk.get_tile_type(local.x, local.y)]

func reveal_tile(world_x, world_y):

	var chunk_x = int(floor(world_x / float(CHUNK_SIZE)))
	var chunk_y = int(floor(world_y / float(CHUNK_SIZE)))

	var key: Vector2i = Vector2i(chunk_x, chunk_y)

	if !loaded_chunks.has(key):
		return
	var chunk = loaded_chunks[key]

	var local_x = posmod(world_x, CHUNK_SIZE)
	var local_y = posmod(world_y, CHUNK_SIZE)

	chunk.reveal(local_x,local_y)

func get_chunk_seed(chunk_x:int, chunk_y:int) -> int:
	return world_generator.terrain_noise.seed ^ (chunk_x * 73856093) ^ (chunk_y * 19349663)

func get_chunk_from_position(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / float(CHUNK_SIZE * TILE_SIZE))),
		int(floor(pos.y / float(CHUNK_SIZE * TILE_SIZE)))
	)

func get_tile_coords_from_world_pos(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / float(TILE_SIZE))),
		int(floor(world_pos.y / float(TILE_SIZE)))
	)

func get_tile_coords_relative_to_chunk(tile_coords: Vector2i) -> Vector2i:
	return Vector2i(
		posmod(tile_coords.x, CHUNK_SIZE),
		posmod(tile_coords.y, CHUNK_SIZE)
	)
