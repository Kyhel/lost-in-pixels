extends Node

const MAX_ENTRIES := 40

var _entries: PackedStringArray = []

signal entry_appended(text: String)
signal cleared

func log_message(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty():
		return
	_entries.append(t)
	while _entries.size() > MAX_ENTRIES:
		_entries.remove_at(0)
	entry_appended.emit(t)


func get_entries() -> PackedStringArray:
	return _entries.duplicate()


func clear() -> void:
	_entries.clear()
	cleared.emit()


func _on_world_reset() -> void:
	clear()
