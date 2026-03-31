class_name TreeFeature
extends WorldObjectFeature

@export var foliage_radius: float = 64.0
@export var foliage_texture: Texture2D
## Added to [constant Constants.Z_INDEX_FOLIAGE] so different tree types can sort above/below each other.
@export var foliage_z_index_offset: int = 0


func apply(node: Node2D) -> void:
	var foliage: Sprite2D = node.get_node_or_null("Foliage") as Sprite2D
	if foliage == null:
		push_warning("TreeFeature: missing Foliage under %s" % str(node.get_path()))
		return

	if foliage_texture != null:
		foliage.texture = foliage_texture
	foliage.z_index = Constants.Z_INDEX_FOLIAGE + foliage_z_index_offset
	_apply_occlusion_mask_to_foliage(node, foliage)

	var tex_size: Vector2 = foliage.texture.get_size()
	var max_f: float = maxf(tex_size.x, tex_size.y)
	if max_f > 0.0:
		var foliage_scale: float = (foliage_radius * 2.0) / max_f
		foliage.scale = Vector2.ONE * foliage_scale


func _find_first_collision_shape(body: StaticBody2D) -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _apply_occlusion_mask_to_foliage(node: Node2D, foliage: Sprite2D) -> void:
	var foliage_material := foliage.material
	if not (foliage_material is ShaderMaterial):
		return
	var scene_tree := node.get_tree()
	if scene_tree == null:
		return
	var scene_root := scene_tree.current_scene
	if scene_root == null:
		return
	var occlusion_mask_viewport := scene_root.find_child("AlphaMaskViewport", true, false) as SubViewport
	if occlusion_mask_viewport == null:
		push_warning("TreeFeature: AlphaMaskViewport missing; tree spawned without mask.")
		return
	(foliage_material as ShaderMaterial).set_shader_parameter("mask_tex", occlusion_mask_viewport.get_texture())
