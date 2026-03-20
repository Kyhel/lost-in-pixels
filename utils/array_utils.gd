class_name ArrayUtils

static func cleanup_invalid_entries(entries: Array) -> Array:
	return entries.filter(func(entry): return is_instance_valid(entry))
