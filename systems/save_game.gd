extends Node
## Save/load JSON to user://.
## v1: world seed, player position/hunger/weapon, fog grids.
## v2: adds player health (loads v1 with full health default).
## v3: adds discovered_abilities (StringName ids).
## v4: adds inventory (per-slot array; null or {id, count}).
## Creatures, dropped items, and trees are not serialized; they follow procedural rules when chunks reload.

func reset_autoload_world_state() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		push_error("SaveGame: no current_scene; cannot emit SystemManager world reset.")
		return
	var system_manager := scene.find_child("SystemManager", true, false)
	if system_manager != null and system_manager.has_method("reset_world_state"):
		system_manager.reset_world_state()
	else:
		push_error("SaveGame: SystemManager missing; cannot emit world reset.")


func save_to_disk(player: Player) -> bool:
	var weapon_path := ""
	if player.weapon != null:
		weapon_path = player.weapon.resource_path
	var ability_ids: Array = []
	for aid in AbilityManager.discovered_order:
		ability_ids.append(String(aid))
	var data := {
		"format_version": GameSession.SAVE_FORMAT_VERSION,
		"world_seed": ChunkManager.get_world_seed(),
		"player": {
			"position": [player.global_position.x, player.global_position.y],
			"hunger": player.hunger,
			"health": player.health,
			"weapon_path": weapon_path,
		},
		"fog_memory": ChunkManager.build_fog_save_payload(),
		"discovered_abilities": ability_ids,
		"inventory": Inventory.serialize_for_save(),
	}
	var json_text := JSON.stringify(data)
	var path := GameSession.SAVE_PATH
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: could not open for write: %s" % path)
		return false
	f.store_string(json_text)
	f.close()
	return true


func load_save_into_pending() -> bool:
	if not FileAccess.file_exists(GameSession.SAVE_PATH):
		return false
	var f := FileAccess.open(GameSession.SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: invalid save file")
		return false
	var d: Dictionary = parsed
	var ver := int(d.get("format_version", 0))
	if ver < 1 or ver > GameSession.SAVE_FORMAT_VERSION:
		push_warning("SaveGame: unsupported format_version %s" % ver)
		return false
	GameSession.set_pending_apply(d)
	return true


func apply_pending_world_before_reload() -> void:
	if not GameSession.has_pending_apply():
		return
	var d: Dictionary = GameSession.pending_apply
	var terrain_seed: int = int(d.get("world_seed", 0))
	if terrain_seed == 0:
		terrain_seed = GameSession.get_active_world_seed()
	reset_autoload_world_state()
	ChunkManager.set_world_seed(terrain_seed)
	var fog: Variant = d.get("fog_memory", [])
	if fog is Array:
		ChunkManager.merge_fog_from_save(fog)


func request_load_game() -> bool:
	if not load_save_into_pending():
		return false
	apply_pending_world_before_reload()
	get_tree().paused = false
	get_tree().reload_current_scene()
	return true


func request_new_game() -> void:
	GameSession.begin_new_game(randi())
	reset_autoload_world_state()
	ChunkManager.set_world_seed(GameSession.get_active_world_seed())
	get_tree().paused = false
	get_tree().reload_current_scene()
