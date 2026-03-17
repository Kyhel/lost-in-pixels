class_name ChunkStagger
extends RefCounted

var interval: float
var timer: float = 0.0
var _chunk_last_cycle: Dictionary = {}

func _init(p_interval: float) -> void:
	interval = p_interval

static func _get_chunk_phase(coords: Vector2i, p_interval: float) -> float:
	var h := (coords.x * 73856093) ^ (coords.y * 19349663)
	return absf(float(h % 10000)) / 10000.0 * p_interval

func update(delta: float) -> Dictionary:
	timer += delta

	if timer >= interval:
		var cycles_elapsed: int = int(floorf(timer / interval))
		timer = fmod(timer, interval)
		for coords in _chunk_last_cycle.keys():
			_chunk_last_cycle[coords] -= float(cycles_elapsed)

	var chunks_to_update: Array[Vector2i] = []

	for chunk in ChunkManager.loaded_chunks.values():
		var coords: Vector2i = chunk.coords
		var phase: float = _get_chunk_phase(coords, interval)
		var current_cycle: float = floorf((timer - phase) / interval)
		var last_cycle: float = _chunk_last_cycle.get(coords, -1.0)
		if current_cycle > last_cycle:
			_chunk_last_cycle[coords] = current_cycle
			chunks_to_update.append(coords)

	var loaded_keys: Array = ChunkManager.loaded_chunks.keys()
	var removed: Array[Vector2i] = []
	for coords in _chunk_last_cycle.keys():
		if coords not in loaded_keys:
			removed.append(coords)
	for coords in removed:
		_chunk_last_cycle.erase(coords)

	return {
		"chunks": chunks_to_update,
		"removed": removed,
	}

