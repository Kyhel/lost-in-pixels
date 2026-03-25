extends PanelContainer

@onready var _log: RichTextLabel = $RichTextLabel


func _ready() -> void:
	GameLog.entry_appended.connect(_on_entry_appended)
	GameLog.cleared.connect(_on_game_log_cleared)
	for line in GameLog.get_entries():
		_append_line(line)


func _on_entry_appended(text: String) -> void:
	_append_line(text)


func _append_line(text: String) -> void:
	_log.append_text(text + "\n")


func _on_game_log_cleared() -> void:
	_log.clear()
