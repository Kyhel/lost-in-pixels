extends RefCounted

var _flower_data: ItemData = preload("res://data/objects/nature/flowers/flower_red_1.tres")


func execute(player: Player) -> void:
	if player == null or not is_instance_valid(player):
		return
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var spawn_pos := player.global_position + forward * float(ChunkManager.TILE_SIZE)
	var chunk := ChunkManager.get_chunk_from_position(spawn_pos)
	ObjectsManager.spawn_item_in_chunk(chunk, _flower_data, spawn_pos, 1)
