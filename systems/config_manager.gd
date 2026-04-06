extends Node

enum CreatureVisibilityCullingSync {
	STEADY_OFF,
	TURNED_OFF,
	STEADY_ON,
	TURNED_ON,
}

var config: Config

var _creature_visibility_prev: bool

func _init() -> void:
	config = load("res://config/config.tres")


func _ready() -> void:
	_creature_visibility_prev = config.creature_visibility_culling


func sync_creature_visibility_state() -> CreatureVisibilityCullingSync:
	var v: bool = config.creature_visibility_culling
	if v == _creature_visibility_prev:
		return CreatureVisibilityCullingSync.STEADY_OFF if not v else CreatureVisibilityCullingSync.STEADY_ON
	_creature_visibility_prev = v
	return CreatureVisibilityCullingSync.TURNED_OFF if not v else CreatureVisibilityCullingSync.TURNED_ON
