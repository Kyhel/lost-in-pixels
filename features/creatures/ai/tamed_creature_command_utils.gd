class_name TamedCreatureCommandUtils
extends RefCounted

## Creatures currently in the Heel goal ([member Groups.HEELING_CREATURES]), sorted by instance id.
static func get_sorted_heeling_creatures(tree: SceneTree) -> Array[Creature]:
	var out: Array[Creature] = []
	if tree == null:
		return out
	for n in tree.get_nodes_in_group(Groups.HEELING_CREATURES):
		if n is Creature and is_instance_valid(n):
			out.append(n as Creature)
	out.sort_custom(func(a: Creature, b: Creature) -> bool: return a.get_instance_id() < b.get_instance_id())
	return out


static func get_heel_slot(creature: Creature) -> Dictionary:
	var sorted := get_sorted_heeling_creatures(creature.get_tree())
	var idx: int = sorted.find(creature)
	var n: int = sorted.size()
	if idx < 0:
		idx = 0
	if n < 1:
		n = 1
	return {"index": idx, "count": n}
