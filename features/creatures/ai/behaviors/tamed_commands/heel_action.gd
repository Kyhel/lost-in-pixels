class_name HeelAction
extends BTNode

@export var heel_distance: float = 72.0
@export var desire: float = 1.0


func tick(creature: Creature, _delta: float) -> State:
	var player := creature.get_tree().get_first_node_in_group(Groups.PLAYER) as Node2D
	if player == null:
		return State.FAILURE

	var slot: Dictionary = TamedCreatureCommandUtils.get_heel_slot(creature)
	var idx: int = int(slot.get("index", 0))
	var n: int = maxi(1, int(slot.get("count", 1)))
	var angle := float(idx) * TAU / float(n)
	var offset := Vector2.from_angle(angle) * heel_distance
	creature.movement.request_movement(MovementRequest.to_orbit_around(player, offset, desire))
	return State.RUNNING
