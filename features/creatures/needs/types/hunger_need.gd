class_name HungerNeed
extends Need


func update(creature: Creature, instance: NeedInstance, delta: float) -> void:
	if creature.creature_data == null:
		return
	instance.set_value(instance.current_value - base_decay_rate * delta)
