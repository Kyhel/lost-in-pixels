class_name MovementComponent
extends Node

var target_position : Vector2
var has_target := false

var strategy: MovementStrategy

func set_strategy(creature: Creature) -> void:
	var movement_type = creature.creature_data.movement_types[0]
	strategy = MovementStrategyDatabase.get_strategy(movement_type).duplicate()

func move_to(pos: Vector2) -> void:
	target_position = pos
	has_target = true

func stop() -> void:
	has_target = false
	strategy.reset()

func update_movement(creature: Creature, delta: float) -> void:

	if not has_target:
		creature.velocity = Vector2.ZERO
		return

	if strategy == null:
		return

	strategy.move(creature, target_position, delta)
