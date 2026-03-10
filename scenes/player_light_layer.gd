extends CanvasLayer

@onready var overlay = $ColorRect

@export var player: Node2D

func _process(delta):
	var mat = overlay.material
	var screen_pos = get_viewport().get_canvas_transform() * player.global_position
	mat.set_shader_parameter("light_pos", screen_pos)
