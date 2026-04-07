class_name EatingFrenzyEffect
extends CreatureEffect

@export var hunger_multiplier := 10.0
@export var color_modulate := Color(0.0, 0.279, 0.426, 1.0)

var _saved_modulate: Color = Color.WHITE
var _received_item_cb: Callable = Callable()


static func find_on(creature: Creature) -> EatingFrenzyEffect:
	if creature == null or not is_instance_valid(creature):
		return null
	for e in creature.get_creature_effects():
		if e is EatingFrenzyEffect:
			return e as EatingFrenzyEffect
	return null


func apply(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	if creature.needs_component == null:
		return
	var inst: NeedInstance = creature.needs_component.get_instance(NeedIds.HUNGER)
	if inst == null:
		return
	inst.current_decay_rate *= hunger_multiplier
	_saved_modulate = creature.visualRoot.modulate
	creature.visualRoot.modulate = _saved_modulate * color_modulate
	_received_item_cb = _on_creature_received_item.bind(creature)
	PlayerCreatureInteractionSystem.creature_received_item.connect(_received_item_cb)


func remove(creature: Creature) -> void:
	if PlayerCreatureInteractionSystem.creature_received_item.is_connected(_received_item_cb):
		PlayerCreatureInteractionSystem.creature_received_item.disconnect(_received_item_cb)
	_received_item_cb = Callable()
	if creature == null or not is_instance_valid(creature):
		return
	if creature.needs_component != null:
		var inst: NeedInstance = creature.needs_component.get_instance(NeedIds.HUNGER)
		if inst != null:
			inst.current_decay_rate /= hunger_multiplier
	creature.visualRoot.modulate = _saved_modulate


func _on_creature_received_item(creature: Creature, item_id: StringName, target: Creature) -> void:
	if creature != target:
		return
	if item_id != ItemIds.NIGHT_FLOWER:
		return
	if not is_instance_valid(creature):
		return
	creature.remove_creature_effect(self)
