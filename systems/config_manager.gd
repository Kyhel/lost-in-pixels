extends Node

enum PlayerLightSync {
	STEADY_OFF,
	TURNED_OFF,
	STEADY_ON,
	TURNED_ON,
}

var config: Config

var _player_light_prev: bool

func _init() -> void:
	config = load("res://config/config.tres")


func _ready() -> void:
	_player_light_prev = config.player_light


func sync_player_light_state() -> PlayerLightSync:
	var v: bool = config.player_light
	if v == _player_light_prev:
		return PlayerLightSync.STEADY_OFF if not v else PlayerLightSync.STEADY_ON
	_player_light_prev = v
	return PlayerLightSync.TURNED_OFF if not v else PlayerLightSync.TURNED_ON
