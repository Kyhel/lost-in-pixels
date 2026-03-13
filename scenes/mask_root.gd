extends Node2D

@export var player_node: Node2D

func _process(_delta: float) -> void:
	if player_node != null:
		position = player_node.get_viewport_transform() * player_node.global_position
