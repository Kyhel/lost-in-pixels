class_name CreatureVisibilitySystem
extends Node

@export var player: Node2D
@export var player_light_layer: CanvasLayer


func _process(_delta: float) -> void:
	var p := player as Player
	if p != null:
		update_visibility(p)


func update_visibility(p: Player) -> void:
	if player_light_layer != null:
		player_light_layer.visible = ConfigManager.config.player_light
	if p == null or not is_instance_valid(p):
		return

	match ConfigManager.sync_player_light_state():
		ConfigManager.PlayerLightSync.STEADY_OFF:
			return
		ConfigManager.PlayerLightSync.TURNED_OFF:
			_restore_all_visible()
			return
		ConfigManager.PlayerLightSync.STEADY_ON, ConfigManager.PlayerLightSync.TURNED_ON:
			_apply_culling(p)


func _restore_all_visible() -> void:
	for chunk_node: Node in ChunkManager.loaded_chunks.values():
		if not is_instance_valid(chunk_node) or not chunk_node is Chunk:
			continue
		var chunk: Chunk = chunk_node as Chunk
		var creatures_container: Node2D = chunk.get_creatures_container()
		if creatures_container == null:
			continue
		creatures_container.visible = true
		for monster_node in creatures_container.get_children():
			var monster: Creature = monster_node as Creature
			if monster == null or !is_instance_valid(monster):
				continue
			monster.visible = true


func _apply_culling(p: Player) -> void:
	var player_pos := p.global_position
	var radius_px := float(p.light_radius)
	var radius_sq := radius_px * radius_px
	var chunk_px := float(ChunkManager.CHUNK_SIZE * ChunkManager.TILE_SIZE)

	for chunk_node: Node in ChunkManager.loaded_chunks.values():
		if not is_instance_valid(chunk_node) or not chunk_node is Chunk:
			continue
		var chunk: Chunk = chunk_node as Chunk
		var creatures_container: Node2D = chunk.get_creatures_container()
		if creatures_container == null:
			continue

		var rect_min := chunk.global_position
		var rect_max := rect_min + Vector2(chunk_px, chunk_px)
		var min_dist_sq := _point_to_aabb_min_distance_sq(player_pos, rect_min, rect_max)

		if min_dist_sq >= radius_sq:
			creatures_container.visible = false
			continue

		creatures_container.visible = true
		for monster_node in creatures_container.get_children():
			var monster: Creature = monster_node as Creature
			if monster == null or !is_instance_valid(monster):
				continue
			var dx := monster.global_position.x - player_pos.x
			var dy := monster.global_position.y - player_pos.y
			var distance_sq := dx * dx + dy * dy
			monster.visible = distance_sq < radius_sq


static func _point_to_aabb_min_distance_sq(p: Vector2, rect_min: Vector2, rect_max: Vector2) -> float:
	var cx := clampf(p.x, rect_min.x, rect_max.x)
	var cy := clampf(p.y, rect_min.y, rect_max.y)
	var dx := p.x - cx
	var dy := p.y - cy
	return dx * dx + dy * dy
