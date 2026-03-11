extends CharacterBody2D
class_name Creature

## Base class for all creatures (player, monsters, etc.).
## Handles common health, damage, and death logic. Override [method _on_die] and
## [method _on_damage_taken] in subclasses to customize behavior.

signal damage_taken(amount: int, source: Node)
signal died

@export var creature_data: CreatureData
@export var max_health: int = 1
var health: int

func _ready() -> void:
	health = max_health
	if creature_data != null:
		if creature_data.sprite != null:
			$Sprite2D.texture = creature_data.sprite
		if creature_data.behavior_tree != null:
			var tree = creature_data.behavior_tree.instantiate()
			tree.name = "BehaviorTree"
			add_child(tree)
		# High-priority creatures don't collide with player so they can overlap and push the player.
		if creature_data.push_priority > PushPriorityHelper.PLAYER_PRIORITY:
			collision_mask = 6  # Terrain + creatures (layer 2 | 4), not player (layer 1)
		else:
			collision_mask = 7  # Player + terrain + creatures


func _physics_process(delta: float) -> void:
	if has_node("BehaviorTree"):
		get_node("BehaviorTree").tick(self, delta)
	move_and_slide()
	if creature_data != null and creature_data.push_priority > PushPriorityHelper.PLAYER_PRIORITY:
		PushPriorityHelper.push_away_player_overlapping(self)


func take_damage(amount: int, source: Node = null) -> void:
	if amount <= 0:
		return
	health = maxi(0, health - amount)
	damage_taken.emit(amount, source)
	_on_damage_taken(amount, source)
	if health <= 0:
		die()


func die() -> void:
	_on_die()
	died.emit()
	queue_free()


## Override in subclasses to run logic when this creature dies (e.g. drops, effects).
func _on_die() -> void:
	pass


## Override in subclasses to react to damage (e.g. knockback, invincibility frames).
func _on_damage_taken(_amount: int, _source: Node) -> void:
	pass
