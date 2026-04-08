class_name CreatureEffectsUtils

static func add_effects(creature: Creature, effects: Array[CreatureEffect]) -> void:

	if effects.is_empty():
		return

	var creature_effects: Array[CreatureEffect] = creature.creature_effects
	for effect in effects:
		if effect.unique and creature_effects.any(func(e: CreatureEffect): return e == effect):
			continue
		creature.creature_effects.append(effect)

	_apply_effects(creature)


static func add_effect(creature: Creature, effect: CreatureEffect) -> void:
	add_effects(creature, [effect])


static func remove_effects(creature: Creature, effects: Array[CreatureEffect]) -> void:

	if effects.is_empty():
		return

	var creature_effects: Array[CreatureEffect] = creature.creature_effects
	for effect in effects:
		creature.creature_effects.erase(effect)

	_apply_effects(creature)
	

static func remove_effect(creature: Creature, effect: CreatureEffect) -> void:
	remove_effects(creature, [effect])


static func _apply_effects(creature: Creature) -> void:

	var creature_effects: Array[CreatureEffect] = creature.creature_effects

	var color_modulates: Array[CreatureEffectColorModulate] = []
	color_modulates.assign(creature_effects.filter(func(effect: CreatureEffect): return effect is CreatureEffectColorModulate))

	_apply_color_modulates(creature, color_modulates)
	
	var need_modifiers: Array[CreatureEffectNeedModifier] = []
	need_modifiers.assign(creature_effects.filter(func(effect: CreatureEffect): return effect is CreatureEffectNeedModifier))

	_apply_need_modifiers(creature, need_modifiers)


static func _apply_color_modulates(creature: Creature, effects: Array[CreatureEffectColorModulate]) -> void:

	var base_modulate := Color.WHITE

	if effects.is_empty():
		creature.visualRoot.modulate = base_modulate
		return

	for effect in _get_additive_effects(effects) as Array[CreatureEffectColorModulate]:
		base_modulate += effect.value

	for effect in _get_multiplicative_effects(effects) as Array[CreatureEffectColorModulate]:
		base_modulate *= effect.value

	for effect in _get_override_effects(effects) as Array[CreatureEffectColorModulate]:
		base_modulate = effect.value

	creature.visualRoot.modulate = base_modulate


static func _apply_need_modifiers(creature: Creature, effects: Array[CreatureEffectNeedModifier]) -> void:

	for need in creature.needs_component.instances.values() as Array[NeedInstance]:
		var need_effects : Array[CreatureEffectNeedModifier] = _fiter_effects_by_need_id(need.need.id, effects)
		var decay_rate := need.need.base_decay_rate
		for effect in _get_additive_effects(need_effects) as Array[CreatureEffectNeedModifier]:
			decay_rate += effect.value
		for effect in _get_multiplicative_effects(need_effects) as Array[CreatureEffectNeedModifier]:
			decay_rate *= effect.value
		for effect in _get_override_effects(need_effects) as Array[CreatureEffectNeedModifier]:
			decay_rate = effect.value
		need.current_decay_rate = decay_rate


static func _fiter_effects_by_need_id(need_id: StringName, effects: Array[CreatureEffectNeedModifier]) -> Array[CreatureEffectNeedModifier]:
	return effects.filter(func(effect: CreatureEffectNeedModifier): return effect.need_id == need_id)


static func _get_additive_effects(effects: Array) -> Array:
	return effects.filter(func(effect: CreatureEffect): return effect.type == CreatureEffect.Type.ADDITIVE)


static func _get_multiplicative_effects(effects: Array) -> Array:
	return effects.filter(func(effect: CreatureEffect): return effect.type == CreatureEffect.Type.MULTIPLICATIVE)


static func _get_override_effects(effects: Array) -> Array:
	return effects.filter(func(effect: CreatureEffect): return effect.type == CreatureEffect.Type.OVERRIDE)
