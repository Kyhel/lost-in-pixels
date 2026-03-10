extends Node2D
class_name AttackEffect

@export var radius: float = 20.0
@export var duration: float = 0.15

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var t := _elapsed / duration
	var alpha := (1.0 - t) * 0.6
	if alpha <= 0.0:
		return

	draw_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, alpha))
