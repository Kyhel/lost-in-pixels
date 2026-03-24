class_name GrowFlowerEffect
extends RefCounted

func execute(player: Player) -> bool:
	var flower_data:= ObjectDatabase.get_object_data(&"flower_red_1")
	if flower_data == null:
		push_error("GrowFlowerEffect: failed to load flower data")
	if player == null or not is_instance_valid(player):
		return false
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var distance := Player.PICKUP_RADIUS + ChunkManager.TILE_SIZE
	var spawn_pos := player.global_position + forward * distance
	if ObjectsManager.is_object_spawn_blocked(spawn_pos, flower_data):
		return false
	ObjectsManager.spawn_object_at(flower_data, spawn_pos)
	return true
