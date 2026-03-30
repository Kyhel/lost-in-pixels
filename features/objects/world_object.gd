extends Area2D
class_name WorldObject

@export var object_data: ObjectData

signal destroyed(reason)

func _ready() -> void:
	if object_data == null:
		return
	object_data = _build_runtime_object_data(object_data)
	if object_data.texture:
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite != null:
			sprite.texture = object_data.texture
			var tex_size: Vector2 = sprite.texture.get_size()
			var target_dim: float = object_data.hitbox_radius * 2.0
			sprite.scale = Vector2.ONE * (target_dim / maxf(tex_size.x, tex_size.y))
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		var base_shape: Shape2D = cs.shape
		if base_shape is CircleShape2D:
			var base_r: float = (base_shape as CircleShape2D).radius
			if base_r > 0.0:
				cs.scale = Vector2.ONE * (object_data.hitbox_radius / base_r)
	_apply_features()
	_apply_behaviors()
	z_index = Constants.Z_INDEX_OBJECTS

func be_eaten(by: Creature) -> void:
	ObjectInteractionSystem.do_eat(by, self)


func destroy(reason: String = "default") -> void:
	emit_signal("destroyed", reason)
	queue_free()


func _build_runtime_object_data(source: ObjectData) -> ObjectData:
	var instance_data := source.duplicate(false) as ObjectData
	if instance_data == null:
		return source
	var resolved_behaviors: Array[WorldObjectBehavior] = []
	for behavior in source.behaviors:
		if behavior == null:
			continue
		var resolved: WorldObjectBehavior = behavior
		if not behavior.shared:
			var duplicated := behavior.duplicate(true)
			if duplicated is WorldObjectBehavior:
				resolved = duplicated as WorldObjectBehavior
		resolved_behaviors.append(resolved)
	instance_data.behaviors = resolved_behaviors
	return instance_data


func _apply_behaviors() -> void:
	for behavior in object_data.behaviors:
		if behavior == null:
			continue
		behavior.apply(self)


func _apply_features() -> void:
	for feature in object_data.features:
		if feature == null:
			continue
		feature.apply(self)
