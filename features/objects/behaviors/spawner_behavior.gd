class_name SpawnerBehavior
extends WorldObjectBehavior

@export var spawn_check_interval: float = 5.0
@export_range(0.0, 1.0, 0.01) var spawn_probability: float = 0.25
@export var creature_data: CreatureData
@export var spawn_rules: Array[SpawnRule] = []


func apply(world_object: WorldObject) -> void:
	if world_object == null:
		return
	if creature_data == null:
		push_warning("SpawnerBehavior: missing creature_data")
		return
	SimulationSystem.register_world_object_tick(
		world_object,
		spawn_check_interval,
		func(_n: Object, _td: float) -> void:
			_tick_spawn(world_object)
	)


func _tick_spawn(world_object: WorldObject) -> void:
	if not ConfigManager.config.spawn_creatures:
		return
	if not is_instance_valid(world_object):
		return
	var world_pos: Vector2 = world_object.global_position
	var context: Dictionary = {}
	for rule in spawn_rules:
		if rule != null and not rule.can_spawn(world_pos, context):
			return
	if randf() >= spawn_probability:
		return
	var spawn_pos: Vector2 = world_pos + Vector2(Chunk.TILE_HALF_SIZE, 0.0)
	var chunk_coords: Vector2i = ChunkUtils.world_pos_to_chunk_coords(spawn_pos)
	CreatureManager.spawn_creature_at(chunk_coords, creature_data, spawn_pos)
