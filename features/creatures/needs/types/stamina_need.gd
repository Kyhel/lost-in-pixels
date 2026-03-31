class_name StaminaNeed
extends Need


func update(_creature: Creature, instance: NeedInstance, delta: float) -> void:
	instance.set_value(instance.current_value - base_decay_rate * delta)
