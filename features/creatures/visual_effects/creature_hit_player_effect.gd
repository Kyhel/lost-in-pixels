extends Node2D
class_name CreatureHitPlayerEffect

@export var duration: float = 0.18
@export var start_scale: float = 0.8
@export var end_scale: float = 1.15

var _elapsed: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.scale = Vector2.ONE * start_scale


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / duration, 0.0, 1.0)
	_sprite.modulate.a = 1.0 - t
	_sprite.scale = Vector2.ONE * lerpf(start_scale, end_scale, t)

	if t >= 1.0:
		queue_free()
