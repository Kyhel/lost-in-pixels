extends Control


func set_watch(creature: Creature) -> void:
	if creature.needs_component == null:
		return
	var hunger_cb := func(id: StringName, value: float) -> void:
		if id == NeedIds.HUNGER:
			$HungerBar.value = value
	creature.needs_component.need_value_changed.connect(hunger_cb)
	$HungerBar.value = creature.needs_component.get_need_value(NeedIds.HUNGER)
