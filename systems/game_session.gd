extends Node
## Holds run-wide state that survives scene reloads (autoload). World seed, pending save/load apply.

const SAVE_PATH := "user://save_slot_0.json"
const SAVE_FORMAT_VERSION := 4

const WELCOME_MESSAGE := "Welcome to Lost in Pixels. The game is what you make of it. Try, fail, experience, die, and let the magic emerge."

## Spawn position for a default run (cold start or New game).
const NEW_GAME_PLAYER_POSITION := Vector2.ZERO

## Current terrain seed used by ChunkManager (noise + chunk RNG).
var active_world_seed: int = 0
var _seed_initialized: bool = false

## After load: applied in [method apply_session_to_player], then cleared via [method take_pending_apply].
var pending_apply: Dictionary = {}

## Set by [method begin_new_game]; cleared in [method apply_session_to_player] for default runs.
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


func apply_session_to_player(player: Player) -> void:
	if player == null:
		return

	if has_pending_apply():
		var data: Dictionary = take_pending_apply()
		var pd: Variant = data.get("player", {})
		if typeof(pd) == TYPE_DICTIONARY:
			var pdict: Dictionary = pd
			var pos: Variant = pdict.get("position", null)
			if pos is Array and pos.size() >= 2:
				player.global_position = Vector2(float(pos[0]), float(pos[1]))
			player.hunger = float(pdict.get("hunger", player.max_hunger))
			player.health = clampf(float(pdict.get("health", player.max_health)), 0.0, player.max_health)
			player.hunger_changed.emit(player.hunger)
			player.health_changed.emit(player.health)
			player._update_attack_hitbox_radius()
		var discovered: Variant = data.get("discovered_abilities", [])
		if discovered is Array:
			AbilityManager.apply_discovered_from_save(discovered)
		else:
			AbilityManager.apply_discovered_from_save([])
		var inv: Variant = data.get("inventory", [])
		Inventory.apply_from_save(inv)
		return

	player.global_position = NEW_GAME_PLAYER_POSITION
	player.hunger = player.max_hunger
	player.health = player.max_health
	player.hunger_changed.emit(player.hunger)
	player.health_changed.emit(player.health)
	player._update_attack_hitbox_radius()
	var starting_ability_ids: Array[StringName] = []
	for ability in ConfigManager.config.starting_abilities:
		var ability_data := ability as AbilityData
		if ability_data == null or ability_data.id == &"":
			continue
		starting_ability_ids.append(ability_data.id)
	AbilityManager.apply_discovered_from_save(starting_ability_ids)
	Inventory.reset()
	consume_new_game()
	GameLog.log_message(WELCOME_MESSAGE)


func start_new_game() -> void:
	begin_new_game(randi())
	SaveGame.reset_autoload_world_state()
	ChunkManager.set_world_seed(get_active_world_seed())
	get_tree().paused = false
	get_tree().reload_current_scene()
