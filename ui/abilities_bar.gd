extends HBoxContainer

const MAX_SLOTS := 10
const SLOT_SIZE := Vector2(52, 52)


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	AbilityManager.discoveries_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	for i in MAX_SLOTS:
		var btn := TextureButton.new()
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = SLOT_SIZE
		btn.disabled = true
		if i < AbilityManager.discovered_order.size():
			var id: StringName = AbilityManager.discovered_order[i]
			var ability: AbilityData = AbilityDatabase.get_ability_data(id)
			if ability != null and ability.icon != null:
				btn.texture_normal = ability.icon
			btn.disabled = false
		add_child(btn)
