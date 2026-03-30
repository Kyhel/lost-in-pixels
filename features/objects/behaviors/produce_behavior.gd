class_name ProduceBehavior
extends WorldObjectBehavior

@export var shared: bool = false
@export var slot_count: int = 1
@export_range(0.0, 1.0, 0.01) var regrow_chance: float = 0.25
@export var regrow_interval: float = 5.0

var slot_refs: Array[WeakRef] = []
var regrow_elapsed: float = 0.0


func apply(world_object: WorldObject) -> void:
	if world_object == null:
		return
	world_object.add_to_group("produce_behavior")
	slot_refs.resize(maxi(slot_count, 0))
	regrow_elapsed = 0.0
