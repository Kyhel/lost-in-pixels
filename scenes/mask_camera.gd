extends Camera2D

@export var main_camera: Camera2D

var zoom_factor: float = 0.25

func _process(_delta: float) -> void:
	if main_camera == null:
		return
	global_transform = main_camera.global_transform
	zoom = main_camera.zoom * zoom_factor
