class_name Vegetation
extends Node2D

enum VegetationKind {
	TREE,
	BERRY_BUSH,
	WATER_LILY,
}

@export var vegetation_kind: VegetationKind = VegetationKind.TREE

@export var features: Array[Resource] = []

## World-space radius of the primary [CollisionShape2D] under the first [StaticBody2D] (circle, after scale).
var hitbox_radius: float = 0.0
## World-space center of that collision shape (for overlap tests).
var hitbox_center_world: Vector2 = Vector2.ZERO

var chunk_coords: Vector2i = Vector2i.ZERO
var world_tile: Vector2i = Vector2i.ZERO


func _ready() -> void:
	for f in features:
		if f != null and f.has_method("apply"):
			f.apply(self)

	var body: StaticBody2D = _find_first_static_body(self)
	if body == null:
		push_warning("Vegetation: no StaticBody2D found under %s" % str(get_path()))
		hitbox_center_world = global_position + Vector2(ChunkManager.TILE_SIZE * 0.5, ChunkManager.TILE_SIZE * 0.5)
		hitbox_radius = 8.0
		return

	var cs: CollisionShape2D = _find_first_collision_shape_in(body)
	if cs != null:
		hitbox_center_world = cs.global_position
	else:
		hitbox_center_world = body.global_position

	hitbox_radius = Node2DUtils.get_collision_radius(body)
	if hitbox_radius <= 0.0:
		hitbox_radius = 8.0


func is_tree() -> bool:
	return vegetation_kind == VegetationKind.TREE


func is_water_lily() -> bool:
	return vegetation_kind == VegetationKind.WATER_LILY


func _find_first_static_body(node: Node) -> StaticBody2D:
	for child in node.get_children():
		if child is StaticBody2D:
			return child as StaticBody2D
		var nested: StaticBody2D = _find_first_static_body(child)
		if nested != null:
			return nested
	return null


func _find_first_collision_shape_in(body: StaticBody2D) -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null
