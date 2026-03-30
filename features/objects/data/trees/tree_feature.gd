class_name TreeFeature
extends WorldObjectFeature

@export var foliage_radius: float = 64.0
@export var trunk_radius: float = 8.0
@export var foliage_texture: Texture2D


func apply(node: Node2D) -> void:
	var foliage: Sprite2D = node.get_node_or_null("Foliage") as Sprite2D
	var trunk: Sprite2D = node.get_node_or_null("Trunk") as Sprite2D
	var trunk_body: StaticBody2D = node.get_node_or_null("TrunkBody") as StaticBody2D
	if foliage == null:
		push_warning("TreeFeature: missing Foliage under %s" % str(node.get_path()))
		return
	if trunk_body == null:
		push_warning("TreeFeature: missing TrunkBody under %s" % str(node.get_path()))
		return

	if foliage_texture != null:
		foliage.texture = foliage_texture
	_apply_occlusion_mask_to_foliage(node, foliage)

	var tex_size: Vector2 = foliage.texture.get_size()
	var max_f: float = maxf(tex_size.x, tex_size.y)
	if max_f > 0.0:
		var foliage_scale: float = (foliage_radius * 2.0) / max_f
		foliage.scale = Vector2.ONE * foliage_scale

	if trunk != null and trunk.texture != null:
		var tt: Vector2 = trunk.texture.get_size()
		var max_t: float = maxf(tt.x, tt.y)
		if max_t > 0.0:
			var trunk_scale: float = (trunk_radius * 2.0) / max_t
			trunk.scale = Vector2.ONE * trunk_scale

	var cs: CollisionShape2D = _find_first_collision_shape(trunk_body)
	if cs == null:
		push_warning("TreeFeature: no CollisionShape2D under TrunkBody")
		return
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var base_r: float = (shape as CircleShape2D).radius
		if base_r > 0.0:
			cs.scale = Vector2.ONE * (trunk_radius / base_r)
	else:
		push_warning("TreeFeature: expected CircleShape2D on tree TrunkBody")


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
