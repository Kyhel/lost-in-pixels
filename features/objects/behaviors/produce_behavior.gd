class_name ProduceBehavior
extends WorldObjectBehavior

@export var produce_object_data: ObjectData
@export var slot_count: int = 1
@export_range(0.0, 1.0, 0.01) var regrow_chance: float = 0.25
@export var regrow_interval: float = 5.0
@export var seed_salt: int = 0


func apply(world_object: WorldObject) -> void:
	if world_object == null:
		return
	world_object.add_to_group(Groups.PRODUCE_BEHAVIOR)
	if produce_object_data == null:
		push_warning("ProduceBehavior: missing produce_object_data")
		return
	var instance := ProduceBehaviorInstance.new()
	_init_slots(world_object, instance)
	world_object.add_behavior_instance(instance)
	for i in range(slot_count):
		_spawn_at_slot(world_object, instance, i)
	SimulationSystem.register_world_object_tick(
		world_object,
		regrow_interval,
		func(_n: Object, _td: float) -> void:
			_tick_regrow(world_object, instance)
	)


func _tick_regrow(world_object: WorldObject, instance: ProduceBehaviorInstance) -> void:
	for i in range(slot_count):
		if _slot_occupied(instance, i):
			continue
		if randf() >= regrow_chance:
			continue
		_spawn_at_slot(world_object, instance, i)


func _slot_occupied(instance: ProduceBehaviorInstance, slot_i: int) -> bool:
	var wr: Variant = instance.slot_refs[slot_i]
	if wr == null:
		return false
	var node: Node = (wr as WeakRef).get_ref()
	return node != null and is_instance_valid(node)


func _spawn_at_slot(world_object: WorldObject, instance: ProduceBehaviorInstance, slot_i: int) -> void:
	var chunk_coords: Vector2i = ChunkManager.world_pos_to_chunk_coords(world_object.global_position)
	var spawned: Variant = ObjectsManager.spawn_object_attached_in_chunk(
		chunk_coords,
		produce_object_data,
		world_object,
		instance.slot_offsets[slot_i]
	)
	if spawned == null or not (spawned is WorldObject):
		return
	var spawned_object := spawned as WorldObject
	instance.slot_refs[slot_i] = weakref(spawned_object)
	spawned_object.destroyed.connect(_on_produced_destroyed.bind(slot_i, instance))


func _on_produced_destroyed(_reason: String, slot_i: int, instance: ProduceBehaviorInstance) -> void:
	instance.slot_refs[slot_i] = null


func _init_slots(world_object: WorldObject, instance: ProduceBehaviorInstance) -> void:
	instance.slot_offsets.clear()
	instance.slot_refs.clear()
	var world_tile: Vector2i = ChunkManager.world_pos_to_world_tile(world_object.global_position)
	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_world_seed() ^ hash(world_tile) ^ seed_salt
	var half_tile: float = Chunk.TILE_SIZE * 0.5
	var base_angle: float = rng.randf_range(0.0, TAU)
	var ring_base: float = half_tile * 0.8
	for i in range(slot_count):
		var angle: float = base_angle + float(i) * TAU / float(slot_count) + rng.randf_range(-0.12, 0.12)
		var r: float = ring_base * rng.randf_range(0.5, 1.0)
		instance.slot_offsets.append(Vector2.from_angle(angle) * r)
		instance.slot_refs.append(null)
