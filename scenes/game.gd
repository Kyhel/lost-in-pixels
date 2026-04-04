extends Node2D

const OCCLUSION_LAYER = 2


func _ready() -> void:
	print("Game started")
	call_deferred(&"_apply_session_to_player")


func _apply_session_to_player() -> void:
	var player: Player = get_tree().get_first_node_in_group(Groups.PLAYER) as Player
	GameSession.apply_session_to_player(player)
