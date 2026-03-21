extends Node

var occlusion_mask_viewport: SubViewport

var chunk_items: Dictionary[Vector2i, Array] = {}
var chunk_trees: Dictionary[Vector2i, Array] = {}

const CHUNK_UPDATE_INTERVAL: float = 10.0
var _chunk_stagger: ChunkStagger = ChunkStagger.new(CHUNK_UPDATE_INTERVAL)

var world_item_scene := preload("res://data/objects/world_item.tscn")
var tree_scene := preload("res://world/nature/tree_1.tscn")

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
	for k in chunk_trees.keys():
		for tree in chunk_trees[k]:
			if is_instance_valid(tree):
				tree.queue_free()
	chunk_trees.clear()

func update_chunks(delta: float) -> void:

	var result: Dictionary = _chunk_stagger.update(delta)
	var chunks_to_check: Array[Vector2i] = result["chunks"]

	# Cleanup invalid items
	for coords in chunks_to_check:
		if chunk_items.has(coords):
			chunk_items[coords] = ArrayUtils.cleanup_invalid_entries(chunk_items[coords])
		if chunk_trees.has(coords):
			chunk_trees[coords] = ArrayUtils.cleanup_invalid_entries(chunk_trees[coords])

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

	if !chunk_trees.has(chunk):
		chunk_trees[chunk] = []

	chunk_trees[chunk].append(tree)

func on_chunk_unloaded(chunk: Vector2i) -> void:

	if chunk_items.has(chunk):

		for item in chunk_items[chunk]:
			if is_instance_valid(item):
				item.queue_free()

		chunk_items.erase(chunk)

	if chunk_trees.has(chunk):

		for tree in chunk_trees[chunk]:
			if is_instance_valid(tree):
				tree.queue_free()	

		chunk_trees.erase(chunk)

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

func get_nearby_trees(origin: Vector2, radius: float) -> Array:
	var results: Array = []
	var radius_sq := radius * radius

	var origin_chunk: Vector2i = ChunkManager.get_chunk_from_position(origin)

	for cx in range(origin_chunk.x - 1, origin_chunk.x + 2):
		for cy in range(origin_chunk.y - 1, origin_chunk.y + 2):
			var key: Vector2i = Vector2i(cx, cy)
			if !chunk_trees.has(key):
				continue

			for tree in chunk_trees[key]:
				if !is_instance_valid(tree):
					continue

				var dx: float = tree.global_position.x - origin.x
				var dy: float = tree.global_position.y - origin.y
				var dist_sq: float = dx * dx + dy * dy

				if dist_sq <= radius_sq:
					results.append(tree)

	return results
