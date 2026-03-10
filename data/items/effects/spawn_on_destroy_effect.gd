extends Resource
class_name SpawnOnDestroyEffect

@export var spawn_item: Resource
@export var count: int = 1


func on_destroy(world_item, _reason: String) -> void:
	if spawn_item == null:
		return

	var chunk: Vector2i = ChunkManager.get_chunk_from_position(world_item.global_position)
	for i in range(count):
		ObjectsManager.spawn_item_in_chunk(chunk, spawn_item, world_item.global_position)

