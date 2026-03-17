class_name Blackboard
extends Resource

const KEY_FOOD := "visible_food"
const KEY_TARGET_FOOD := "target_food"
const KEY_PREDATORS := "visible_predators"
const KEY_STATE := "state"
const KEY_HUNGER := "hunger"

const KEY_HUNGER_MAX := 100

enum State {
	IDLE,
	EATING,
}

signal value_changed(key, value)

var data := {}

func set_value(key, value):

	if data.has(key) and data[key] == value:
		return

	data[key] = value
	value_changed.emit(key, value)

func get_value(key):
	return data.get(key)

func has(key):
	return data.has(key)

func clear(key):
	data.erase(key)

func watch(key, callable):
	value_changed.connect(
		func(k, v):
			if k == key:
				callable.call(v)
	)
