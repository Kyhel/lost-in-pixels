extends CanvasLayer

@onready var _confirm_new: AcceptDialog = $ConfirmNewGame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	var p := get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	if p is Player:
		(p as Player).died.connect(_on_player_died)


func _on_player_died() -> void:
	visible = true
	get_tree().paused = true


func _on_restore_pressed() -> void:
	if not FileAccess.file_exists(GameSession.SAVE_PATH):
		return
	SaveGame.request_load_game()


func _on_new_game_pressed() -> void:
	_confirm_new.popup_centered()


func _on_confirm_new_confirmed() -> void:
	get_tree().paused = false
	SaveGame.request_new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
