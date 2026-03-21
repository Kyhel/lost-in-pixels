extends HBoxContainer

const SLOT_SIZE := Vector2(52, 52)


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	AbilityManager.discoveries_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	for id in AbilityManager.discovered_order:
		var ability := AbilityManager.get_ability(id)
		if ability == null:
			continue
		var btn := TextureButton.new()
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = SLOT_SIZE
		if ability.icon != null:
			btn.texture_normal = ability.icon
		add_child(btn)
