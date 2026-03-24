extends Resource
class_name SpawnOnDestroyEffect

@export var spawn_object_data: ObjectData
@export var count: int = 1


func on_destroy(world_object, _reason: String) -> void:
	if spawn_object_data == null:
		return

	for i in range(count):
		ObjectsManager.spawn_object_at(spawn_object_data, world_object.global_position)
