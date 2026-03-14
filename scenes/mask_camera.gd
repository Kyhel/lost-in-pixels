extends Camera2D

@export var main_camera: Camera2D

func _process(_delta: float) -> void:
	if main_camera == null:
		return
	
	global_position = main_camera.global_position
	zoom = main_camera.zoom
	rotation = main_camera.rotation
