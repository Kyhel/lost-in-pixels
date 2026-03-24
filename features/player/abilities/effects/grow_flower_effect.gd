extends RefCounted

var _flower_data: ItemData = preload("res://data/objects/nature/flowers/flower_red_1.tres")


func execute(player: Player) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var distance := Player.PICKUP_RADIUS + ChunkManager.TILE_SIZE
	var spawn_pos := player.global_position + forward * distance
	if ObjectsManager.is_item_spawn_blocked(spawn_pos, _flower_data):
		return false
	ObjectsManager.spawn_item_at(_flower_data, spawn_pos, 1)
	return true
