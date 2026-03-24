extends Node

signal object_picked_up(actor: Node, world_object: WorldObject)
signal object_eaten(eater: Creature, world_object: WorldObject)
signal creature_eaten(eater: Creature, prey: Creature)
signal player_got_hit(attacker: Node, player: Player, amount: int)


func _ready() -> void:
	player_got_hit.connect(_on_player_got_hit)


func _on_player_got_hit(attacker: Node, _player: Player, amount: int) -> void:
	var attacker_name := _attacker_display_name(attacker)
	GameLog.log_message("You were hit for %d damage by %s" % [amount, attacker_name])


func _attacker_display_name(attacker: Node) -> String:
	if attacker is Creature:
		var c: Creature = attacker
		if c.creature_data != null:
			var dn: String = c.creature_data.display_name.strip_edges()
			if not dn.is_empty():
				return dn
	return "something"
