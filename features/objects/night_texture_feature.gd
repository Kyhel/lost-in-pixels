class_name NightTextureFeature
extends WorldObjectFeature

@export var night_texture: Texture2D


func apply(node: Node2D) -> void:
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		push_warning("NightTextureFeature: missing Sprite2D under %s" % str(node.get_path()))
		return
	var world_object := node as WorldObject
	if world_object == null or world_object.object_data == null:
		push_warning("NightTextureFeature: expected WorldObject with object_data at %s" % str(node.get_path()))
		return

	var default_texture: Texture2D = world_object.object_data.texture

	var refresh := func(_phase: DayNightCycle.CyclePhase) -> void:
		if DayNightCycle.is_night_phase() and night_texture != null:
			sprite.texture = night_texture
		else:
			sprite.texture = default_texture

	refresh.call(DayNightCycle.current_phase)
	DayNightCycle.phase_changed.connect(refresh)
	var cleanup := func() -> void:
		if DayNightCycle.phase_changed.is_connected(refresh):
			DayNightCycle.phase_changed.disconnect(refresh)
	node.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
