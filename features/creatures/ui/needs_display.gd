extends Control


func set_watch(creature: Creature) -> void:
	if creature.needs_component == null:
		return
	var hunger_cb := func(value: float) -> void:
		$HungerBar.value = value
	var hunger_need := creature.needs_component.get_instance(NeedIds.HUNGER)
	if hunger_need != null:
		hunger_need.value_changed.connect(hunger_cb)
	
	$HungerBar.value = creature.needs_component.get_need_value(NeedIds.HUNGER)
