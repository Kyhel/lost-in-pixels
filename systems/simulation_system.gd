extends Node

## Central staggered updates for sensors, AI, world object ticks (produce, spawners), and creature needs.

## Global step between sensor ticks. At most one tick per entry per interval. <= 0 runs every physics frame.
@export var sensor_update_interval: float = 0.2
## Global step between AI ticks. <= 0 runs every physics frame.
@export var ai_update_interval: float = 0.1
## Global step between creature need ticks. At most one tick per creature per interval.
@export var need_update_interval: float = 0.1

var _sensor_entries: Array[Dictionary] = []
var _ai_entries: Array[Dictionary] = []
var _world_object_entries: Array[Dictionary] = []
var _needs_entries: Array[Dictionary] = []


func _on_world_reset() -> void:
	_sensor_entries.clear()
	_ai_entries.clear()
	_world_object_entries.clear()
	_needs_entries.clear()


func register_sensor(root: SensorsRoot, on_tick: Callable) -> void:
	_register_entry(_sensor_entries, root, sensor_update_interval, on_tick)


func register_ai(root: AIRoot, on_tick: Callable) -> void:
	_register_entry(_ai_entries, root, ai_update_interval, on_tick)


func register_world_object_tick(world_object: WorldObject, interval: float, on_tick: Callable) -> void:
	_register_world_object_entry(world_object, interval, on_tick)


func register_needs(creature: Creature, on_tick: Callable) -> void:
	_register_entry(_needs_entries, creature, need_update_interval, on_tick)


func _remove_entry_by_node(entries: Array[Dictionary], node: Object) -> void:
	for i in range(entries.size() - 1, -1, -1):
		var n: Object = entries[i].node_wr.get_ref()
		if n == node:
			entries.remove_at(i)


func _register_entry(entries: Array[Dictionary], node: Object, interval: float, on_tick: Callable) -> void:
	if node == null or not on_tick.is_valid():
		return
	_remove_entry_by_node(entries, node)
	var phase: float = _get_stagger_phase_offset(node, interval)
	entries.append({
		"node_wr": weakref(node),
		"elapsed": -phase,
		"on_tick": on_tick,
	})


func _register_world_object_entry(node: Object, interval: float, on_tick: Callable) -> void:
	if node == null or not on_tick.is_valid():
		return
	_remove_entry_by_node(_world_object_entries, node)
	var phase: float = _get_stagger_phase_offset(node, interval)
	_world_object_entries.append({
		"node_wr": weakref(node),
		"elapsed": -phase,
		"on_tick": on_tick,
		"interval": interval,
	})


func _physics_process(delta: float) -> void:
	_process_stagger_queue(_sensor_entries, sensor_update_interval, delta)
	_process_stagger_queue(_ai_entries, ai_update_interval, delta)
	_process_world_object_entries(delta)
	_process_stagger_queue(_needs_entries, need_update_interval, delta)


## Returns null if this frame did not cross a tick (elapsed may be updated only). If interval <= 0, always returns delta (every physics frame).
func _advance_stagger_timer(e: Dictionary, delta: float, interval: float) -> Variant:
	if interval <= 0.0:
		return delta
	var elapsed: float = e.elapsed + delta
	if elapsed < interval:
		e.elapsed = elapsed
		return null
	var tick_delta: float = elapsed
	e.elapsed = fmod(elapsed, interval)
	return tick_delta


## Advances timers without resolving weakrefs. Only resolves the node when a tick fires, then runs entry on_tick (per-entry lambdas capture validated refs).
func _process_stagger_queue(entries: Array[Dictionary], interval: float, delta: float) -> void:
	var i := 0
	while i < entries.size():
		var e: Dictionary = entries[i]
		var tick_delta: Variant = _advance_stagger_timer(e, delta, interval)
		if tick_delta == null:
			i += 1
			continue
		var node: Object = e.node_wr.get_ref()
		if node == null:
			entries.remove_at(i)
			continue
		(e.on_tick as Callable).call(node, tick_delta as float)
		i += 1


func _process_world_object_entries(delta: float) -> void:
	var i := 0
	while i < _world_object_entries.size():
		var e: Dictionary = _world_object_entries[i]
		var interval: float = float(e.get("interval", 5.0))
		var tick_delta: Variant = _advance_stagger_timer(e, delta, interval)
		if tick_delta == null:
			i += 1
			continue
		var node: Object = e.node_wr.get_ref()
		if node == null:
			_world_object_entries.remove_at(i)
			continue
		(e.on_tick as Callable).call(node, tick_delta as float)
		i += 1

## Returns a deterministic phase offset in [0, interval) for staggered updates.
## Uses the owner's instance id to spread creatures across frames.
static func _get_stagger_phase_offset(p_owner: Object, interval: float) -> float:
	if interval <= 0.0:
		return 0.0
	if p_owner == null:
		return 0.0

	var hash_source: int = p_owner.get_instance_id()
	var normalized := absf(float(hash_source % 10000)) / 10000.0
	return normalized * interval
