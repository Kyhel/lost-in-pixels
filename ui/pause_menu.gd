extends CanvasLayer

@onready var _confirm_new: AcceptDialog = $ConfirmNewGame

var _open: bool = false


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


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		close_pause()
		get_viewport().set_input_as_handled()


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
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Player", true, false) as Player
