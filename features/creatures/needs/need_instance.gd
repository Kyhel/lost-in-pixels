class_name NeedInstance
extends RefCounted

const MAX_VALUE: float = 100.0
const MIN_VALUE: float = 0.0

signal value_changed(id: StringName, value: float)

var need: Need
var current_value: float = 0.0
var current_decay_rate: float = 0.0


func _init(p_need: Need) -> void:
	need = p_need

func setup() -> void:
	current_decay_rate = need.base_decay_rate
	set_value(need.initial_value)

func set_value(v: float) -> void:
	var nv := clampf(v, MIN_VALUE, MAX_VALUE)
	if nv == current_value:
		return
	current_value = nv
	value_changed.emit(need.id, current_value)
