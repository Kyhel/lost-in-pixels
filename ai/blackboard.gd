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

var data := {}

func set_value(key, value):
    data[key] = value

func get_value(key):
    return data.get(key)

func has(key):
    return data.has(key)

func clear(key):
    data.erase(key)
