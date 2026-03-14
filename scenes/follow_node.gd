extends Node2D

@export var node: Node2D

func _process(_delta: float) -> void:
	if node != null:
		position = node.global_position
