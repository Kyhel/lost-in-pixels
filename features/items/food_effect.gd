class_name FoodEffect
extends "res://features/items/consume_effect.gd"

@export var amount: float = 0.0


func apply(player: Node) -> void:
	ObjectInteractionSystem.apply_food_amount_to_player(player as Player, amount)
