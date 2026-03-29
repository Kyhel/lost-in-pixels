class_name TamingBehavior
extends WorldObjectBehavior

@export var taming_value: int = 0


static func get_taming_value(od: ObjectData) -> int:
	for b in od.behaviors:
		if b is TamingBehavior:
			return (b as TamingBehavior).taming_value
	return 0


static func has_taming(od: ObjectData) -> bool:
	for b in od.behaviors:
		if b is TamingBehavior:
			if (b as TamingBehavior).taming_value > 0:
				return true
	return false
