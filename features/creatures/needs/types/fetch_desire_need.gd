class_name FetchDesireNeed
extends Need

const MODULATION_MIN: float = 0.8
const MODULATION_MAX: float = 1.2


func update(_creature: Creature, instance: NeedInstance, delta: float) -> void:
	var modulation := randf_range(MODULATION_MIN, MODULATION_MAX)
	var recharge_amount := -base_decay_rate * delta * modulation
	instance.set_value(instance.current_value + recharge_amount)
