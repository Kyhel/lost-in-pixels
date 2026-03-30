class_name WaterLily
extends Vegetation

const SLOT_COUNT := 3
const LILY_SEED_SALT := 0x7A1E1E1E

@export var regrow_chance: float = 0.1

var _flower_data: ObjectData
var _slot_offsets: Array[Vector2] = []
var _slot_refs: Array = []

var _regrow_elapsed: float = 0.0
const REGROW_INTERVAL := 5.0


func _ready() -> void:
	super._ready()
	_regrow_elapsed = -CreatureUtils.get_stagger_phase_offset(self, REGROW_INTERVAL)
	_flower_data = ObjectDatabase.get_object_data(&"water_lily_flower")
	if _flower_data == null:
		push_error("WaterLily: water_lily_flower object data not in ObjectDatabase")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = ChunkManager.get_world_seed() ^ hash(world_tile) ^ LILY_SEED_SALT

	var half_tile: float = ChunkManager.TILE_SIZE * 0.5
	var base_angle: float = rng.randf_range(0.0, TAU)
	var ring_base: float = half_tile * 0.8
	for i in SLOT_COUNT:
		var angle: float = base_angle + float(i) * TAU / float(SLOT_COUNT) + rng.randf_range(-0.12, 0.12)
		var r: float = ring_base * rng.randf_range(0.5, 1.0)
		_slot_offsets.append(Vector2.from_angle(angle) * r)
		_slot_refs.append(null)

	for slot_i in SLOT_COUNT:
		_spawn_flower_at_slot(slot_i)


func _physics_process(delta: float) -> void:
	if _flower_data == null:
		return
	_regrow_elapsed += delta
	while _regrow_elapsed >= REGROW_INTERVAL:
		_regrow_elapsed -= REGROW_INTERVAL
		_tick_regrow()


func _tick_regrow() -> void:
	for slot_i in SLOT_COUNT:
		if _slot_occupied(slot_i):
			continue
		if randf() >= regrow_chance:
			continue
		_spawn_flower_at_slot(slot_i)


func _slot_occupied(slot_i: int) -> bool:
	var wr: Variant = _slot_refs[slot_i]
	if wr == null:
		return false
	var node: Node = (wr as WeakRef).get_ref()
	return node != null and is_instance_valid(node)


func _spawn_flower_at_slot(slot_i: int) -> void:
	if _flower_data == null:
		return
	var spawned = ObjectsManager.spawn_object_attached_in_chunk(
		chunk_coords,
		_flower_data,
		self,
		_slot_offsets[slot_i],
	)
	if spawned == null or not spawned is WorldObject:
		return
	var world_object: WorldObject = spawned as WorldObject
	var wr: WeakRef = weakref(world_object)
	_slot_refs[slot_i] = wr
	world_object.destroyed.connect(_on_flower_destroyed.bind(slot_i))


func _on_flower_destroyed(_reason: String, slot_i: int) -> void:
	_clear_slot(slot_i)


func _clear_slot(slot_i: int) -> void:
	_slot_refs[slot_i] = null
