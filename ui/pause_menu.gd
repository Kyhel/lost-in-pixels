extends CanvasLayer

@onready var _confirm_new: AcceptDialog = $ConfirmNewGame
@onready var _main_vbox: VBoxContainer = $Panel/VBox
@onready var _debug_vbox: VBoxContainer = $Panel/DebugVBox
@onready var _event_list: VBoxContainer = $Panel/DebugVBox/ScrollContainer/EventList

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


func _on_debug_pressed() -> void:
	_main_vbox.hide()
	_debug_vbox.show()
	_refresh_area_event_buttons()


func _on_debug_back_pressed() -> void:
	_debug_vbox.hide()
	_main_vbox.show()


func _refresh_area_event_buttons() -> void:
	for child in _event_list.get_children():
		child.queue_free()
	for ev_any in AreaEventDatabase.get_all():
		if ev_any == null or not ev_any is AreaEvent:
			continue
		var ev: AreaEvent = ev_any as AreaEvent
		var btn := Button.new()
		btn.text = String(ev.id)
		btn.pressed.connect(_on_area_event_button_pressed.bind(ev))
		_event_list.add_child(btn)


func _on_area_event_button_pressed(event_data: AreaEvent) -> void:
	var p: Player = _get_player()
	if p == null:
		return
	event_data.apply(p.global_position)


func _get_player() -> Player:
	var player := get_tree().get_first_node_in_group(Groups.PLAYER)
	if player == null:
		return null
	return player as Player
