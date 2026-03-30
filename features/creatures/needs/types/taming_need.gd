class_name TamingNeed
extends Need


func update(creature: Creature, instance: NeedInstance, delta: float) -> void:
	var data := creature.creature_data
	if data == null or data.taming_value_threshold <= 0:
		return
	if creature.blackboard.get_value(Blackboard.KEY_TAMED) == true:
		return
	var taming := instance.current_value
	taming = maxf(0.0, taming - base_decay_rate * delta)
	instance.set_value(taming)
