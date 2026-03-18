extends Node

var debug_config: DebugConfig

func _ready() -> void:
	debug_config = load("res://managers/debug_config.tres")
