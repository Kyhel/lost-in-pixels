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
const LAYER_FLYING_CREATURES := 64   # layer 6

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

var virtual_rotation: float = 0

@onready var visualRoot: = $Visuals
@onready var collisionShape: = $CollisionShape

func _ready() -> void:

	sensors_node = get_node("Sensors")
	ai_root = get_node("AI")
	movement = get_node("Movement")
	blackboard = Blackboard.new()
	health = max_health
	$UIRoot/NeedsDisplay.set_watch(self)

	if creature_data != null:

		if !creature_data.can_fly:
			var mask_world = get_tree().current_scene.find_child("MaskWorld")
			alpha_mask = alpha_mask_scene.instantiate()
			alpha_mask.node = self
			mask_world.add_child(alpha_mask)

		for goal in creature_data.goals:
			goals.append(goal)
		if creature_data.taming_value_threshold > 0:
			blackboard.set_value(Blackboard.KEY_TAMING, 0)
			blackboard.set_value(Blackboard.KEY_TAMED, false)
		is_big = creature_data.size_type == CreatureData.CreatureSize.BIG
		if creature_data.sprite != null:
			$Visuals.texture = creature_data.sprite
			var texture_size = $Visuals.texture.get_size()
			$Visuals.scale = Vector2.ONE * (float(creature_data.size) / max(texture_size.x, texture_size.y))
		_setup_sensors()
		# Assign layer and mask from creature size (Small = layer 4, Big = layer 5).
		collision_layer = _get_collision_layer()
		collision_mask = _get_collision_mask()
		scale = Vector2.ONE * creature_data.scale_factor
		$CollisionShape.scale = Vector2.ONE * creature_data.size / $CollisionShape.shape.radius / 2
		if creature_data.can_fly:
			z_index = 20

func _process(_delta: float) -> void:
	_update_visuals()

func _physics_process(delta: float) -> void:
	sensors_node.update_sensors(delta)
	ai_root.update_ai(delta)
	movement.update_movement(self, delta)
	move_and_slide()
	_update_hunger(delta)
	_update_taming(delta)
	#if is_big:  # BIG
		#PushPriorityHelper.push_away_overlapping(self, LAYER_SMALL_CREATURES | LAYER_PLAYER)
			
func _update_visuals() -> void:
	visualRoot.rotation = virtual_rotation
	collisionShape.rotation = virtual_rotation

func _get_collision_layer() -> int:

	if creature_data.can_fly:
		return LAYER_FLYING_CREATURES | LAYER_ENNEMIES

	if is_big:
		return LAYER_BIG_CREATURES | LAYER_ENNEMIES
	else:
		return LAYER_SMALL_CREATURES | LAYER_ENNEMIES

func _get_collision_mask() -> int:

	if creature_data.can_fly:
		return 0
	
	if is_big:
		return LAYER_TERRAIN | LAYER_BIG_CREATURES
	else:
		return LAYER_TERRAIN | LAYER_PLAYER | LAYER_SMALL_CREATURES | LAYER_BIG_CREATURES

func _update_hunger(delta: float) -> void:

	if not creature_data.needs_eating:
		return

	var hunger = blackboard.get_value(Blackboard.KEY_HUNGER)

	if hunger == null:
		hunger = Blackboard.KEY_HUNGER_MAX
		blackboard.set_value(Blackboard.KEY_HUNGER, hunger)

	blackboard.set_value(Blackboard.KEY_HUNGER, hunger - creature_data.hunger_decay_rate * delta)

func _update_taming(delta: float) -> void:
	if creature_data == null or creature_data.taming_value_threshold <= 0:
		return
	if blackboard.get_value(Blackboard.KEY_TAMED) == true:
		return
	var taming = blackboard.get_value(Blackboard.KEY_TAMING)
	if taming == null:
		taming = 0.0
	taming = maxf(0.0, taming - creature_data.taming_decay_rate * delta)
	blackboard.set_value(Blackboard.KEY_TAMING, taming)

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
	if is_instance_valid(alpha_mask):
		alpha_mask.queue_free()
	queue_free()

func be_eaten(by: Creature) -> void:
	die()

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
