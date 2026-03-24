extends Node
## Holds run-wide state that survives scene reloads (autoload). World seed, pending save/load apply.

const SAVE_PATH := "user://save_slot_0.json"
const SAVE_FORMAT_VERSION := 4

## Current terrain seed used by ChunkManager (noise + chunk RNG).
var active_world_seed: int = 0
var _seed_initialized: bool = false

## After load: applied in game.gd _ready, then cleared via [method take_pending_apply].
var pending_apply: Dictionary = {}

## Set by [method begin_new_game]; consumed in game scene [method _ready].
var pending_new_game: bool = false

func get_active_world_seed() -> int:
	if not _seed_initialized:
		active_world_seed = randi()
		_seed_initialized = true
	return active_world_seed


func set_active_world_seed(p_seed: int) -> void:
	active_world_seed = p_seed
	_seed_initialized = true


func set_pending_apply(data: Dictionary) -> void:
	pending_apply = data


func take_pending_apply() -> Dictionary:
	var d := pending_apply
	pending_apply = {}
	return d


func has_pending_apply() -> bool:
	return not pending_apply.is_empty()


func begin_new_game(p_seed: int) -> void:
	set_active_world_seed(p_seed)
	pending_apply.clear()
	pending_new_game = true


func consume_new_game() -> bool:
	var v := pending_new_game
	pending_new_game = false
	return v
