extends CanvasLayer

@onready var _confirm_new: AcceptDialog = $ConfirmNewGame

var _open: bool = false


func is_pause_open() -> bool:
	return _open


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false


func toggle_pause_menu() -> void:
	if _open:
		close_pause()
	else:
		open_pause()


func open_pause() -> void:
	_open = true
	visible = true
	get_tree().paused = true


func close_pause() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	close_pause()


func _on_save_pressed() -> void:
	var p: Player = _get_player()
	if p:
		SaveGame.save_to_disk(p)


func _on_restore_pressed() -> void:
	if not FileAccess.file_exists(GameSession.SAVE_PATH):
		return
	SaveGame.request_load_game()


func _on_new_game_pressed() -> void:
	_confirm_new.popup_centered()


func _on_confirm_new_confirmed() -> void:
	close_pause()
	SaveGame.request_new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _get_player() -> Player:
	var player := get_tree().get_first_node_in_group(Groups.PLAYER)
	if player == null:
		return null
	return player as Player
