extends Node

## Centralizes menu-related input: Esc / pause key cascade and creature-menu state.

var _creature_menu_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_creature_menu_open(open: bool) -> void:
	_creature_menu_open = open


func is_creature_menu_open() -> bool:
	return _creature_menu_open


func should_block_player_movement() -> bool:
	return _creature_menu_open or _is_pause_menu_open() or get_tree().paused


func _is_pause_menu_open() -> bool:
	var pm := _get_pause_menu()
	if pm != null and pm.has_method(&"is_pause_open"):
		return pm.is_pause_open()
	return false


func _get_pause_menu() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("PauseMenuRoot", true, false)


func _get_death_overlay() -> CanvasLayer:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var n := scene.find_child("DeathOverlay", true, false)
	return n as CanvasLayer


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel") and not event.is_action_pressed(&"pause_menu"):
		return
	_handle_back_or_pause()


func _handle_back_or_pause() -> void:
	if PlayerCreatureInteractionSystem.is_interaction_open():
		PlayerCreatureInteractionSystem.end_interaction()
		get_viewport().set_input_as_handled()
		return

	var pm := _get_pause_menu()
	if pm != null and pm.has_method(&"is_pause_open") and pm.is_pause_open():
		if pm.has_method(&"close_pause"):
			pm.close_pause()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		# e.g. death overlay — do not open pause on top
		var death := _get_death_overlay()
		if death != null and death.visible:
			get_viewport().set_input_as_handled()
			return
		return

	if pm != null and pm.has_method(&"open_pause"):
		pm.open_pause()
	get_viewport().set_input_as_handled()


func try_toggle_pause_menu() -> void:
	## Used when unpaused: open pause menu (same as Escape when no other menu).
	if PlayerCreatureInteractionSystem.is_interaction_open():
		return
	var pm := _get_pause_menu()
	if pm != null and pm.has_method(&"open_pause"):
		pm.open_pause()
