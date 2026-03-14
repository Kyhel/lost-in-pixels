extends Node2D

const OCCLUSION_LAYER = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Game started")
	# var root_viewport = get_tree().root.get_viewport()
	# Example: Exclude objects on layer 2 (occlusion layer)
	# root_viewport.canvas_cull_mask = root_viewport.canvas_cull_mask & ~OCCLUSION_LAYER
