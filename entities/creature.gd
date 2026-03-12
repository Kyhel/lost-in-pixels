extends CharacterBody2D
class_name Creature

## Base class for all creatures (player, monsters, etc.).
## Handles common health, damage, and death logic. Override [method _on_die] and
## [method _on_damage_taken] in subclasses to customize behavior.

## Physics layer bits (project: 1=Player, 2=Terrain, 3=Enemies, 4=Small creatures, 5=Big creatures).
const LAYER_PLAYER := 1
const LAYER_TERRAIN := 2
const LAYER_ENNEMIES := 4
const LAYER_SMALL_CREATURES := 8   # layer 4
const LAYER_BIG_CREATURES := 16   # layer 5

signal damage_taken(amount: int, source: Node)
signal died

@export var creature_data: CreatureData
@export var max_health: int = 1
var health: int
var is_big: bool

func _ready() -> void:
	health = max_health
	if creature_data != null:
		is_big = creature_data.size_type == CreatureData.CreatureSize.BIG
		if creature_data.sprite != null:
			$Sprite2D.texture = creature_data.sprite
			$Sprite2D.scale = Vector2(creature_data.size, creature_data.size) / $Sprite2D.texture.get_size()
		if creature_data.behavior_tree != null:
			var tree = creature_data.behavior_tree.instantiate()
			tree.name = "BehaviorTree"
			add_child(tree)
		# Assign layer and mask from creature size (Small = layer 4, Big = layer 5).
		if is_big:
			collision_layer = LAYER_BIG_CREATURES | LAYER_ENNEMIES
			collision_mask = LAYER_TERRAIN | LAYER_BIG_CREATURES  # Terrain + other Big creatures
		else:
			collision_layer = LAYER_SMALL_CREATURES | LAYER_ENNEMIES
			collision_mask = LAYER_TERRAIN | LAYER_PLAYER | LAYER_SMALL_CREATURES | LAYER_BIG_CREATURES  # Terrain, player, all creatures
		scale = Vector2.ONE * creature_data.scale_factor
		$CollisionShape2D.scale = Vector2.ONE * creature_data.size / $CollisionShape2D.shape.radius / 2

func _physics_process(delta: float) -> void:
	if has_node("BehaviorTree"):
		get_node("BehaviorTree").tick(self, delta)
	move_and_slide()
	if is_big:  # BIG
		PushPriorityHelper.push_away_overlapping(self, LAYER_SMALL_CREATURES | LAYER_PLAYER)


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
