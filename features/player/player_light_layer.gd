extends CanvasLayer

@onready var overlay = $ColorRect

@export var player: Player

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var mat: Material = overlay.material
	if mat == null:
		return
	var xf: Transform2D = get_viewport().get_canvas_transform()
	var screen_pos: Vector2 = xf * player.global_position
	var screen_total: float = xf.basis_xform(Vector2(player.player_config.light_radius, 0)).length()
	var screen_soft: float = xf.basis_xform(Vector2(player.player_config.light_softness, 0)).length()
	var shader_radius: float = maxf(0.0, screen_total - screen_soft)
	mat.set_shader_parameter("light_pos", screen_pos)
	mat.set_shader_parameter("radius", shader_radius)
	mat.set_shader_parameter("softness", screen_soft)
