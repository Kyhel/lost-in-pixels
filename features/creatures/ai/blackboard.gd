class_name Blackboard
extends Resource

const KEY_FOOD := "visible_food"
const KEY_FETCHABLES := "visible_fetchables"
const KEY_TARGET_OBJECT := "target_object"
const KEY_TARGET_CREATURE := "target_creature"
const KEY_PREDATORS := "visible_predators"
const KEY_STATE := "state"
const KEY_TAMED := "tamed"
const KEY_SEES_PLAYER := "sees_player"
const KEY_AGGRESSIVENESS := "aggressiveness"
## When true, aggressiveness does not build up; cleared only when aggressiveness reaches 0.
const KEY_AGGRESSIVENESS_RECOVERING := "aggressiveness_recovering"
const KEY_CHASING_STATE := "chasing_state"
const KEY_TAME_COMMAND := "tame_command"
## Wall-clock deadline ([method Time.get_ticks_msec]) while [constant KEY_TAME_COMMAND] is Stay.
const KEY_STAY_END_TIME_MS := "stay_end_time_ms"

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
