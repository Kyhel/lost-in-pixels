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

var alpha_mask_scene := preload("res://scenes/alpha.tscn")

@export var creature_data: CreatureData
@export var max_health: int = 1
var health: int
var is_big: bool
var blackboard: Blackboard  ## Shared memory for sensors and behaviors (e.g. found_food).
var goals : Array[Goal] = []
var sensors_node : SensorsRoot
var ai_root : AIRoot
var movement : MovementComponent
var alpha_mask: Node2D

func _ready() -> void:

	var mask_world = get_tree().current_scene.find_child("MaskWorld")
	alpha_mask = alpha_mask_scene.instantiate()
	alpha_mask.node = self
	mask_world.add_child(alpha_mask)

	sensors_node = get_node("Sensors")
	ai_root = get_node("AI")
	movement = get_node("Movement")
	blackboard = Blackboard.new()
	health = max_health

	if creature_data != null:
		if creature_data.walking_speed > 0:
			movement.walking_speed = creature_data.walking_speed
		if creature_data.rotating_speed > 0:
			movement.rotating_speed = creature_data.rotating_speed
		for goal in creature_data.goals:
			goals.append(goal)
		is_big = creature_data.size_type == CreatureData.CreatureSize.BIG
		if creature_data.sprite != null:
			$Sprite2D.texture = creature_data.sprite
			var texture_size = $Sprite2D.texture.get_size()
			$Sprite2D.scale = Vector2.ONE * (float(creature_data.size) / max(texture_size.x, texture_size.y))
		_setup_sensors()
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
	sensors_node.update_sensors(delta)
	ai_root.update_ai(delta)
	movement.update_movement(self, delta)
	move_and_slide()
	#if is_big:  # BIG
		#PushPriorityHelper.push_away_overlapping(self, LAYER_SMALL_CREATURES | LAYER_PLAYER)


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
	alpha_mask.queue_free()
	queue_free()


## Override in subclasses to run logic when this creature dies (e.g. drops, effects).
func _on_die() -> void:
	pass


## Override in subclasses to react to damage (e.g. knockback, invincibility frames).
func _on_damage_taken(_amount: int, _source: Node) -> void:
	pass


func _setup_sensors() -> void:

	if creature_data.sensor_scenes.is_empty():
		return

	for scene in creature_data.sensor_scenes:
		if scene == null:
			continue
		var sensor_node: Node = scene.instantiate()
		if sensor_node is Sensor:
			sensors_node.add_child(sensor_node)
		else:
			sensor_node.queue_free()
