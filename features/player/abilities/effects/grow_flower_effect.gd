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
	var spawn_data := flower_data.duplicate(true) as ObjectData
	var taming_behavior := TamingBehavior.new()
	taming_behavior.taming_value = GROWN_FLOWER_TAMING_VALUE
	var replaced := false
	for i in range(spawn_data.behaviors.size()):
		if spawn_data.behaviors[i] is TamingBehavior:
			spawn_data.behaviors[i] = taming_behavior
			replaced = true
			break
	if not replaced:
		spawn_data.behaviors.append(taming_behavior)
	var forward := Vector2.from_angle(player.sprite.rotation - TAU / 4.0)
	var distance := Player.PICKUP_RADIUS
	var spawn_pos := player.global_position + forward * distance
	if ObjectsManager.is_object_spawn_blocked(spawn_pos, spawn_data):
		return false
	ObjectsManager.spawn_object_at(spawn_data, spawn_pos)
	return true
