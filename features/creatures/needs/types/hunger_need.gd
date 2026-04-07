class_name HungerNeed
extends Need

## Item types this species can eat; used by [FoodSensor] together with [member edible_creatures].
@export var edible_objects: Array[ObjectData] = []
## Prey species ([CreatureData]) this species can eat; used by [FoodSensor].
@export var edible_creatures: Array[CreatureData] = []

func update(creature: Creature, instance: NeedInstance, delta: float) -> void:
	if creature.creature_data == null:
		return
	instance.set_value(instance.current_value - instance.current_decay_rate * delta)
