extends Node

var occlusion_mask_viewport: SubViewport

var chunk_items: Dictionary[Vector2i, Array] = {}
var chunk_vegetation: Dictionary[Vector2i, Array] = {}

## World tile anchors for trees, berry bushes, water lilies, etc. (not small world items).
var _environment_tile_occupied: Dictionary = {}

const FALLBACK_WORLD_ITEM_RADIUS := 4.0
const PLACEMENT_MARGIN := 4.0
const OVERLAP_SEARCH_RADIUS := 64.0

const CHUNK_UPDATE_INTERVAL: float = 10.0
var _chunk_stagger: ChunkStagger = ChunkStagger.new(CHUNK_UPDATE_INTERVAL)

var world_item_scene := preload("res://data/objects/world_item.tscn")
var tree_scene := preload("res://world/nature/tree_1.tscn")
var berry_bush_scene := preload("res://world/nature/berry_bush.tscn")
var water_lily_scene: PackedScene = preload("res://world/nature/water_lily.tscn")

func _ready() -> void:
	refresh_scene_references()


func refresh_scene_references() -> void:
	var scene := get_tree().current_scene
	if scene:
		occlusion_mask_viewport = scene.find_child("AlphaMaskViewport", true, false) as SubViewport


func clear_all_objects() -> void:
	for k in chunk_items.keys():
		for item in chunk_items[k]:
			if is_instance_valid(item):
				item.queue_free()
	chunk_items.clear()
	for k in chunk_vegetation.keys():
		for veg in chunk_vegetation[k]:
			if is_instance_valid(veg):
				veg.queue_free()
	chunk_vegetation.clear()
	_environment_tile_occupied.clear()

func update_chunks(delta: float) -> void:

	var result: Dictionary = _chunk_stagger.update(delta)
	var chunks_to_check: Array[Vector2i] = result["chunks"]

	# Cleanup invalid items
	for coords in chunks_to_check:
		if chunk_items.has(coords):
			chunk_items[coords] = ArrayUtils.cleanup_invalid_entries(chunk_items[coords])
		if chunk_vegetation.has(coords):
			chunk_vegetation[coords] = ArrayUtils.cleanup_invalid_entries(chunk_vegetation[coords])

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

func spawn_tree(chunk: Vector2i, tile_position:Vector2i) -> void:
	if occlusion_mask_viewport == null or not is_instance_valid(occlusion_mask_viewport):
		refresh_scene_references()
	var tree := tree_scene.instantiate()
	var foliage_material = tree.get_node("Foliage").material
	if occlusion_mask_viewport != null:
		foliage_material.set_shader_parameter("mask_tex", occlusion_mask_viewport.get_texture())
	else:
		push_warning("ObjectsManager: AlphaMaskViewport missing; tree spawned without mask.")

	tree.global_position = Vector2(
		tile_position.x * ChunkManager.TILE_SIZE,
		tile_position.y * ChunkManager.TILE_SIZE
	)
	
	add_child(tree)

	if !chunk_vegetation.has(chunk):
		chunk_vegetation[chunk] = []

	chunk_vegetation[chunk].append(tree)
	register_environment_tile(tile_position)


func spawn_berry_bush(chunk: Vector2i, world_tile: Vector2i) -> void:
	var bush: Node2D = berry_bush_scene.instantiate() as Node2D
	bush.set("chunk_coords", chunk)
	bush.set("world_tile", world_tile)
	bush.global_position = Vector2(
		world_tile.x * ChunkManager.TILE_SIZE,
		world_tile.y * ChunkManager.TILE_SIZE
	)
	add_child(bush)
	if not chunk_vegetation.has(chunk):
		chunk_vegetation[chunk] = []
	chunk_vegetation[chunk].append(bush)
	register_environment_tile(world_tile)


func spawn_water_lily(chunk: Vector2i, world_tile: Vector2i) -> void:
	var lily: Node2D = water_lily_scene.instantiate() as Node2D
	lily.set("chunk_coords", chunk)
	lily.set("world_tile", world_tile)
	lily.global_position = Vector2(
		world_tile.x * ChunkManager.TILE_SIZE,
		world_tile.y * ChunkManager.TILE_SIZE
	)
	add_child(lily)
	if not chunk_vegetation.has(chunk):
		chunk_vegetation[chunk] = []
	chunk_vegetation[chunk].append(lily)
	register_environment_tile(world_tile)


func register_environment_tile(world_tile: Vector2i) -> void:
	_environment_tile_occupied[world_tile] = true


func is_environment_tile_occupied(world_tile: Vector2i) -> bool:
	return _environment_tile_occupied.has(world_tile)


func clear_environment_tiles_for_chunk(chunk_coords: Vector2i) -> void:
	for ly in ChunkManager.CHUNK_SIZE:
		for lx in ChunkManager.CHUNK_SIZE:
			var wx: int = chunk_coords.x * ChunkManager.CHUNK_SIZE + lx
			var wy: int = chunk_coords.y * ChunkManager.CHUNK_SIZE + ly
			_environment_tile_occupied.erase(Vector2i(wx, wy))


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
	for veg in get_nearby_vegetation(world_pos, OVERLAP_SEARCH_RADIUS):
		if _vegetation_blocks_point(world_pos, self_radius, margin, veg):
			return true
	return false


func _vegetation_blocks_point(world_pos: Vector2, self_radius: float, margin: float, node: Vegetation) -> bool:
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


func on_chunk_unloaded(chunk: Vector2i) -> void:

	clear_environment_tiles_for_chunk(chunk)

	if chunk_items.has(chunk):

		for item in chunk_items[chunk]:
			if is_instance_valid(item):
				item.queue_free()

		chunk_items.erase(chunk)

	if chunk_vegetation.has(chunk):

		for veg in chunk_vegetation[chunk]:
			if is_instance_valid(veg):
				veg.queue_free()

		chunk_vegetation.erase(chunk)

func get_nearby_items(origin: Vector2, radius: float) -> Array[WorldItem]:
	var results: Array[WorldItem] = []
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

func get_nearby_vegetation(origin: Vector2, radius: float) -> Array[Vegetation]:
	var results: Array[Vegetation] = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			if not chunk_vegetation.has(key):
				continue

			for veg in chunk_vegetation[key]:
				if not is_instance_valid(veg):
					continue

				var dx: float = veg.global_position.x - origin.x
				var dy: float = veg.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(veg as Vegetation)

	return results


func get_nearby_trees(origin: Vector2, radius: float) -> Array[Vegetation]:
	var out: Array[Vegetation] = []
	for veg in get_nearby_vegetation(origin, radius):
		if veg.is_tree():
			out.append(veg)
	return out
