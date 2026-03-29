class_name PlayerEatableBehavior
extends WorldObjectBehavior

@export var player_food_value: int = 0


static func get_food_value(od: ObjectData) -> int:
	for b in od.behaviors:
		if b is PlayerEatableBehavior:
			return (b as PlayerEatableBehavior).player_food_value
	return 0
