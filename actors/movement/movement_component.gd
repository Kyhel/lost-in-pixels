class_name MovementComponent
extends Node

var current_request: MovementRequest = null

var strategy: MovementStrategy

func set_strategy(creature: Creature) -> void:
	var movement_type = creature.creature_data.movement_types[0]
	strategy = MovementStrategyDatabase.get_strategy(movement_type).duplicate()

func request_movement(request: MovementRequest) -> void:
	current_request = request

func stop() -> void:
	current_request = null
	strategy.reset()

func update_movement(creature: Creature, delta: float) -> void:

	if current_request == null:
		creature.velocity = Vector2.ZERO
		return

	if strategy == null:
		return

	strategy.move(creature, current_request.target_position, delta)
