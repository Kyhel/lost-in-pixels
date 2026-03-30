class_name ProduceBehavior
extends WorldObjectBehavior

@export var produce_object_data: ObjectData
@export var slot_count: int = 1
@export_range(0.0, 1.0, 0.01) var regrow_chance: float = 0.25
@export var regrow_interval: float = 5.0
@export var seed_salt: int = 0

var slot_offsets: Array[Vector2] = []
var slot_refs: Array[Variant] = []
var regrow_elapsed: float = 0.0


func _init() -> void:
	shared = false
	ticks_in_physics = true


func apply(world_object: WorldObject) -> void:
	if world_object == null:
		return
	world_object.add_to_group("produce_behavior")
	if produce_object_data == null:
		push_warning("ProduceBehavior: missing produce_object_data")
		return
	_init_slots(world_object)
	regrow_elapsed = -CreatureUtils.get_stagger_phase_offset(world_object, regrow_interval)
	for i in range(slot_count):
		_spawn_at_slot(world_object, i)


func physics_update(world_object: WorldObject, delta: float) -> void:
	if world_object == null or regrow_interval <= 0.0:
		return
	if produce_object_data == null:
		return
	regrow_elapsed += delta
	while regrow_elapsed >= regrow_interval:
		regrow_elapsed -= regrow_interval
		_tick_regrow(world_object)


func _tick_regrow(world_object: WorldObject) -> void:
	for i in range(slot_count):
		if _slot_occupied(i):
			continue
		if randf() >= regrow_chance:
			continue
		_spawn_at_slot(world_object, i)


func _slot_occupied(slot_i: int) -> bool:
	var wr: Variant = slot_refs[slot_i]
	if wr == null:
		return false
	var node: Node = (wr as WeakRef).get_ref()
	return node != null and is_instance_valid(node)


func _spawn_at_slot(world_object: WorldObject, slot_i: int) -> void:
	var chunk_coords: Vector2i = ChunkManager.world_pos_to_chunk_coords(world_object.global_position)
	var spawned: Variant = ObjectsManager.spawn_object_attached_in_chunk(
		chunk_coords,
		produce_object_data,
		world_object,
		slot_offsets[slot_i]
	)
	if spawned == null or not (spawned is WorldObject):
		return
	var spawned_object := spawned as WorldObject
	slot_refs[slot_i] = weakref(spawned_object)
	spawned_object.destroyed.connect(_on_produced_destroyed.bind(slot_i))


func _on_produced_destroyed(_reason: String, slot_i: int) -> void:
	slot_refs[slot_i] = null


func _init_slots(world_object: WorldObject) -> void:
	slot_offsets.clear()
	slot_refs.clear()
	var world_tile: Vector2i = ChunkManager.world_pos_to_world_tile(world_object.global_position)
	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_world_seed() ^ hash(world_tile) ^ seed_salt
	var half_tile: float = ChunkManager.TILE_SIZE * 0.5
	var base_angle: float = rng.randf_range(0.0, TAU)
	var ring_base: float = half_tile * 0.8
	for i in range(slot_count):
		var angle: float = base_angle + float(i) * TAU / float(slot_count) + rng.randf_range(-0.12, 0.12)
		var r: float = ring_base * rng.randf_range(0.5, 1.0)
		slot_offsets.append(Vector2.from_angle(angle) * r)
		slot_refs.append(null)
