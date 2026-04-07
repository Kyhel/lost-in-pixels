extends CharacterBody2D
class_name Creature

## Base class for all creatures (player, monsters, etc.).
## Handles common health, damage, and death logic. Override [method _on_die] and
## [method _on_damage_taken] in subclasses to customize behavior.

## Physics layer bits (project: 1=Player, 2=Terrain, 3=Enemies, 4=Small creatures, 5=Big creatures).

signal damage_taken(amount: int, source: Node)
signal died

@export var alpha_mask_scene : PackedScene

@export var creature_data: CreatureData
@export var max_health: int = 1
var health: int
var is_big: bool
var blackboard: Blackboard  ## Shared memory for sensors and behaviors (e.g. found_food).
var sensors_node : SensorsRoot
var ai_root : AIRoot
var movement : MovementComponent
var needs_component: NeedsComponent
var alpha_mask: Node2D

var virtual_rotation: float = 0

var _creature_effects: Array[CreatureEffect] = []

@onready var visualRoot: = $Visuals
@onready var heldItemAnchor: Node2D = $Visuals/HeldItem
@onready var collisionShape: = $CollisionShape
@onready var creature_debug: CreatureDebug = get_node_or_null("Debug") as CreatureDebug

## Cached obstacle-avoidance query (per creature so shared [MovementStrategy] resources stay thread-safe).
var _obstacle_avoid_query_params: PhysicsShapeQueryParameters2D
var _obstacle_avoid_rect_shape: RectangleShape2D

func _ready() -> void:

	sensors_node = get_node("Sensors")
	ai_root = get_node("AI")
	movement = get_node("Movement")
	blackboard = Blackboard.new()
	health = max_health

	if creature_data != null:

		if !creature_data.can_fly:
			var mask_world = get_tree().current_scene.find_child("MaskWorld")
			alpha_mask = alpha_mask_scene.instantiate()
			alpha_mask.node = self
			mask_world.add_child(alpha_mask)

		is_big = creature_data.size_type == CreatureData.CreatureSize.BIG
		if creature_data.sprite != null:
			$Visuals.texture = creature_data.sprite
			var texture_size = $Visuals.texture.get_size()
			$Visuals.scale = Vector2.ONE * (float(creature_data.size) / max(texture_size.x, texture_size.y))
		# Assign layer and mask from creature size (Small = layer 4, Big = layer 5).
		collision_layer = _get_collision_layer()
		collision_mask = _get_collision_mask()
		scale = Vector2.ONE * creature_data.scale_factor
		$CollisionShape.scale = Vector2.ONE * creature_data.hitbox_size / $CollisionShape.shape.radius / 2
		z_index = _get_z_index()

	needs_component = NeedsComponent.new(creature_data)
	_initialize_hunger_need_starting_value()
	if needs_component != null and needs_component.has_any():
		SimulationSystem.register_needs(self,
		func(_n: Object, tick_delta: float) -> void:
			needs_component.update_all(self, tick_delta))

	$UIRoot/NeedsDisplay.set_watch(self)


func _initialize_hunger_need_starting_value() -> void:
	if needs_component == null:
		return
	var inst := needs_component.get_instance(NeedIds.HUNGER)
	if inst == null:
		return
	var hunger_need := inst.need as HungerNeed
	if hunger_need == null:
		return
	inst.set_value(randf_range(NeedInstance.MAX_VALUE * 0.8, NeedInstance.MAX_VALUE))


func _process(_delta: float) -> void:
	_update_visuals()

func _get_z_index() -> int:
	if creature_data.can_fly:
		return Constants.Z_INDEX_FLYING_CREATURES
	if is_big:
		return Constants.Z_INDEX_BIG_CREATURES
	else:
		return Constants.Z_INDEX_SMALL_CREATURES

func _physics_process(delta: float) -> void:
	if creature_debug != null:
		creature_debug.reset_vectors()

	if creature_data != null:
		for goal in creature_data.goals:
			goal.update(self, delta)

	movement.update_movement(self, delta)

	move_and_slide()

func _update_visuals() -> void:
	visualRoot.rotation = virtual_rotation
	collisionShape.rotation = virtual_rotation

func _get_collision_layer() -> int:

	if creature_data.can_fly:
		return Layers.FLYING_CREATURES

	if is_big:
		return Layers.BIG_CREATURES
	else:
		return Layers.SMALL_CREATURES

func _get_collision_mask() -> int:

	if creature_data.can_fly:
		return 0

	var mask = Layers.TERRAIN | Layers.BIG_CREATURES | Layers.ENVIRONMENT | Layers.WATER

	if not is_big:
		mask |= Layers.PLAYER | Layers.SMALL_CREATURES

	if creature_data.can_swim:
		mask &= ~Layers.WATER

	return mask

func get_goal_priority(goal: Goal) -> int:
	if creature_data == null or goal == null:
		return 0
	return creature_data.get_priority_for_goal(goal)


## Approximate this creature's collision "radius" based on its configured hitbox size.
## Used by AI contact/approach logic (e.g. stop when the creature is close enough).
func get_hitbox_radius() -> float:
	if creature_data == null:
		return 0.0
	return creature_data.hitbox_size * 0.5


func get_obstacle_avoidance_shape_query() -> PhysicsShapeQueryParameters2D:
	if _obstacle_avoid_query_params == null:
		_obstacle_avoid_rect_shape = RectangleShape2D.new()
		_obstacle_avoid_query_params = PhysicsShapeQueryParameters2D.new()
		_obstacle_avoid_query_params.shape = _obstacle_avoid_rect_shape
		_obstacle_avoid_query_params.collide_with_bodies = true
		_obstacle_avoid_query_params.collide_with_areas = false
	return _obstacle_avoid_query_params


func add_creature_effect(effect: CreatureEffect) -> void:
	if effect == null:
		return
	_creature_effects.append(effect)


func remove_creature_effect(effect: CreatureEffect) -> void:
	if effect == null:
		return
	var i := _creature_effects.find(effect)
	if i < 0:
		return
	effect.remove(self)
	_creature_effects.remove_at(i)


func get_creature_effects() -> Array[CreatureEffect]:
	return _creature_effects.duplicate()


func get_held_item_anchor() -> Node2D:
	return heldItemAnchor


func get_held_world_object() -> WorldObject:
	if heldItemAnchor == null:
		return null
	for child in heldItemAnchor.get_children():
		if child is WorldObject and is_instance_valid(child):
			return child as WorldObject
	return null


func is_holding_world_object() -> bool:
	return get_held_world_object() != null


func hold_world_object(world_object: WorldObject) -> bool:
	if world_object == null or not is_instance_valid(world_object):
		return false
	if heldItemAnchor == null:
		return false
	var current := get_held_world_object()
	if current != null and current != world_object:
		return false

	var parent := world_object.get_parent()
	if parent != null:
		parent.remove_child(world_object)
	heldItemAnchor.add_child(world_object)
	world_object.position = Vector2.ZERO
	return true


func clear_held_world_object(destroy_held: bool = false) -> void:
	var held := get_held_world_object()
	if held == null or not is_instance_valid(held):
		return
	if destroy_held:
		held.queue_free()

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
	EventManager.creature_eaten.emit(by, self)
	die()

## Override in subclasses to run logic when this creature dies (e.g. drops, effects).
func _on_die() -> void:
	pass


## Override in subclasses to react to damage (e.g. knockback, invincibility frames).
func _on_damage_taken(_amount: int, _source: Node) -> void:
	pass
