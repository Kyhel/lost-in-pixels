class_name Blackboard
extends Resource

const KEY_FOOD := "visible_food"
const KEY_TARGET_FOOD := "target_food"
const KEY_PREDATORS := "visible_predators"
const KEY_STATE := "state"
const KEY_HUNGER := "hunger"
const KEY_TAMING := "taming"
const KEY_TAMED := "tamed"
const KEY_SEES_PLAYER := "sees_player"
const KEY_AGGRESSIVENESS := "aggressiveness"
## When true, aggressiveness does not build up; cleared only when aggressiveness reaches 0.
const KEY_AGGRESSIVENESS_RECOVERING := "aggressiveness_recovering"
const KEY_CHASING_STATE := "chasing_state"
const KEY_FEAR := "fear"
## Fear at or above this value triggers flee goal scoring.
const KEY_FEAR_FLEE_THRESHOLD := 80

const KEY_HUNGER_MAX := 100

enum State {
	IDLE,
	EATING
}

enum ChasingState {
	IDLE,
	CHASING,
	RECOVERING
}

signal value_changed(key, value)

var data := {}

func set_value(key, value):

	if data.has(key) and data[key] == value:
		return

	data[key] = value
	value_changed.emit(key, value)

func get_value(key, default_value = null):
	return data.get(key, default_value)

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
