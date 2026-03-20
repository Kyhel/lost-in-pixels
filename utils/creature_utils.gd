class_name CreatureUtils

## Returns a deterministic phase offset in [0, interval) for staggered updates.
## Uses the owner's instance id to spread creatures across frames.
static func get_stagger_phase_offset(owner: Object, interval: float) -> float:
	if interval <= 0.0:
		return 0.0
	if owner == null:
		return 0.0

	var hash_source: int = owner.get_instance_id()
	var normalized := absf(float(hash_source % 10000)) / 10000.0
	return normalized * interval
