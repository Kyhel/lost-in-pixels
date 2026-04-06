extends PointLight2D


func _ready() -> void:
	_apply_from_player_config()


func _process(_delta: float) -> void:
	visible = ConfigManager.config.player_light and DayNightCycle.is_night()


func _apply_from_player_config() -> void:
	var configured_radius: float = float(ConfigManager.config.player_config.light_radius)
	if texture != null:
		var texture_width: float = maxf(1.0, texture.get_size().x)
		texture_scale = (configured_radius * 2.0) / texture_width
