extends Node2D

const OCCLUSION_LAYER = 2

## Spawn position after "New game" (scene default used on first cold start).
const NEW_GAME_PLAYER_POSITION := Vector2.ZERO


func _ready() -> void:
	print("Game started")
	ObjectsManager.refresh_scene_references()
	call_deferred(&"_apply_session_to_player")


func _apply_session_to_player() -> void:
	var player: Player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER) as Player
	if player == null:
		return

	if GameSession.consume_new_game():
		player.global_position = NEW_GAME_PLAYER_POSITION
		player.hunger = player.max_hunger
		player.health = player.max_health
		player.hunger_changed.emit(player.hunger)
		player.health_changed.emit(player.health)
		player._update_attack_hitbox_radius()
		AbilityManager.apply_discovered_from_save([])
	elif GameSession.has_pending_apply():
		var data: Dictionary = GameSession.take_pending_apply()
		var pd: Variant = data.get("player", {})
		if typeof(pd) == TYPE_DICTIONARY:
			var pdict: Dictionary = pd
			var pos: Variant = pdict.get("position", null)
			if pos is Array and pos.size() >= 2:
				player.global_position = Vector2(float(pos[0]), float(pos[1]))
			player.hunger = float(pdict.get("hunger", player.max_hunger))
			player.health = clampf(float(pdict.get("health", player.max_health)), 0.0, player.max_health)
			var wpath: String = str(pdict.get("weapon_path", ""))
			if wpath != "" and ResourceLoader.exists(wpath):
				player.weapon = load(wpath)
			player.hunger_changed.emit(player.hunger)
			player.health_changed.emit(player.health)
			player._update_attack_hitbox_radius()
		var discovered: Variant = data.get("discovered_abilities", [])
		if discovered is Array:
			AbilityManager.apply_discovered_from_save(discovered)
		else:
			AbilityManager.apply_discovered_from_save([])
