class_name TamingNeed
extends Need

@export var taming_value_threshold: int = 0


static func get_taming_value_threshold(data: CreatureData) -> int:
	if data == null:
		return 0
	for n in data.needs:
		if n is TamingNeed:
			return (n as TamingNeed).taming_value_threshold
	return 0


func update(creature: Creature, instance: NeedInstance, delta: float) -> void:
	if creature.creature_data == null or taming_value_threshold <= 0:
		return
	if creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return
	var taming := instance.current_value
	taming = maxf(0.0, taming - base_decay_rate * delta)
	instance.set_value(taming)
