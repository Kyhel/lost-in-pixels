extends Node

var _items_by_id: Dictionary = {}

func _ready() -> void:
	_register_defaults()


func _register_defaults() -> void:
	_register_item(load("res://data/items/health_potion.tres"))
	_register_item(load("res://data/items/berry.tres"))
	_register_item(load("res://data/items/water_lily_flower.tres"))
	_register_item(load("res://data/items/coin.tres"))
	_register_item(load("res://data/objects/nature/flowers/flower_red_1.tres"))

func _register_item(item: ItemData) -> void:
	if item == null:
		return
	_items_by_id[item.id] = item


func get_item(id: StringName) -> ItemData:
	return _items_by_id.get(id, null)

func get_items() -> Array:
	return _items_by_id.values()
