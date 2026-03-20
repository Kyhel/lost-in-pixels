extends SubViewport

@export var scale_factor: float = 0.25

func _ready() -> void:
	_resize_viewport()
	get_parent().get_viewport().size_changed.connect(_resize_viewport)

func _resize_viewport() -> void:
	self.size = get_parent().get_viewport().get_visible_rect().size * scale_factor
	$MaskCamera.zoom_factor = scale_factor
