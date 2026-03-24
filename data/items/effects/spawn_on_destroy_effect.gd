extends Resource
class_name SpawnOnDestroyEffect

@export var spawn_item: Resource
@export var count: int = 1


func on_destroy(world_item, _reason: String) -> void:
	if spawn_item == null:
		return

	for i in range(count):
		ObjectsManager.spawn_item_at(spawn_item, world_item.global_position)
