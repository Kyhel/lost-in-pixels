extends Area2D
class_name WorldItem

@export var item_data: ItemData
@export var quantity: int = 1

signal picked_up(by)
signal used(user, target)
signal destroyed(reason)

func _ready() -> void:
	if item_data and item_data.texture:
		var sprite := $Sprite2D
		sprite.texture = item_data.texture

func can_be_picked_up(by: Node) -> bool:
	return true

func be_eaten(by: Creature) -> void:
	on_picked_up(by)

func on_picked_up(by: Node) -> void:
	if item_data and item_data.pickup_effect_script:
		var eff = item_data.pickup_effect_script.new()
		if eff.has_method("on_pickup"):
			eff.on_pickup(self, by)

	emit_signal("picked_up", by)
	destroy("picked_up")


func use_on(user: Node, target: Node = null) -> void:
	if item_data and item_data.use_effect_script:
		var eff = item_data.use_effect_script.new()
		if eff.has_method("on_use"):
			eff.on_use(self, user, target)

	emit_signal("used", user, target)


func destroy(reason: String = "default") -> void:
	if item_data and item_data.destroy_effect_script:
		var eff = item_data.destroy_effect_script.new()
		if eff.has_method("on_destroy"):
			eff.on_destroy(self, reason)

	emit_signal("destroyed", reason)
	queue_free()
