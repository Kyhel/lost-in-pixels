class_name Need
extends Resource

@export var id: StringName = &""
@export var base_decay_rate: float = 0.0
## If negative, hunger is randomized at creature spawn (see Creature).
@export var initial_value: float = 0.0


func update(_creature: Creature, _instance: NeedInstance, _delta: float) -> void:
	pass
