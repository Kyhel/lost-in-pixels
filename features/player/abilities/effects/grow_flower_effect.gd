class_name GrowFlowerEffect
extends RefCounted

const GROWN_FLOWER_TAMING_VALUE := 20

func execute(player: Player) -> bool:
	var flower_data := ObjectDatabase.get_object_data(&"flower_red_1")
	if flower_data == null:
		push_error("GrowFlowerEffect: failed to load flower data")
		return false
	if player == null or not is_instance_valid(player):
		return false
	var spawn_data := flower_data.duplicate(false) as ObjectData
	spawn_data.taming_value = GROWN_FLOWER_TAMING_VALUE
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var distance := Player.PICKUP_RADIUS + ChunkManager.TILE_SIZE
	var spawn_pos := player.global_position + forward * distance
	if ObjectsManager.is_object_spawn_blocked(spawn_pos, spawn_data):
		return false
	ObjectsManager.spawn_object_at(spawn_data, spawn_pos)
	return true
