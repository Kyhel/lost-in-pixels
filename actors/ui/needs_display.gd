extends Control


func set_watch(_creature: Creature) -> void:
	_creature.blackboard.watch(Blackboard.KEY_HUNGER, func(value: float) -> void:
		$HungerBar.value = value
		#pass
	)
