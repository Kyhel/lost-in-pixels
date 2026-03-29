extends Area2D
class_name WorldObject

@export var object_data: ObjectData

signal destroyed(reason)

func _ready() -> void:
	if object_data == null:
		return
	if object_data.texture:
		var sprite := $Sprite2D
		sprite.texture = object_data.texture
		var tex_size: Vector2 = sprite.texture.get_size()
		var target_dim: float = object_data.hitbox_radius * 2.0
		sprite.scale = Vector2.ONE * (target_dim / maxf(tex_size.x, tex_size.y))
	var cs: CollisionShape2D = $CollisionShape2D
	var base_shape: Shape2D = cs.shape
	if base_shape is CircleShape2D:
		var base_r: float = (base_shape as CircleShape2D).radius
		if base_r > 0.0:
			cs.scale = Vector2.ONE * (object_data.hitbox_radius / base_r)
	z_index = Constants.Z_INDEX_OBJECTS

func be_eaten(by: Creature) -> void:
	ObjectInteractionSystem.do_eat(by, self)


func destroy(reason: String = "default") -> void:
	emit_signal("destroyed", reason)
	queue_free()
