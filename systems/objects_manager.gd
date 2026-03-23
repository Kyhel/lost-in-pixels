extends Node

var chunk_items: Dictionary[Vector2i, Array] = {}

const FALLBACK_WORLD_ITEM_RADIUS := 4.0
const PLACEMENT_MARGIN := 4.0
const OVERLAP_SEARCH_RADIUS := 64.0

const CHUNK_UPDATE_INTERVAL: float = 10.0
var _chunk_stagger: ChunkStagger = ChunkStagger.new(CHUNK_UPDATE_INTERVAL)

var world_item_scene := preload("res://data/objects/world_item.tscn")


func clear_all_objects() -> void:
	for k in chunk_items.keys():
		for item in chunk_items[k]:
			if is_instance_valid(item):
				item.queue_free()
	chunk_items.clear()

func update_chunks(delta: float) -> void:

	var result: Dictionary = _chunk_stagger.update(delta)
	var chunks_to_check: Array[Vector2i] = result["chunks"]

	# Cleanup invalid items
	for coords in chunks_to_check:
		if chunk_items.has(coords):
			chunk_items[coords] = ArrayUtils.cleanup_invalid_entries(chunk_items[coords])

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

func on_chunk_unloaded(chunk: Vector2i) -> void:
	if chunk_items.has(chunk):

		for item in chunk_items[chunk]:
			if is_instance_valid(item):
				item.queue_free()

		chunk_items.erase(chunk)

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
