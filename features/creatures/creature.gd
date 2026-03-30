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

## Debug vectors for movement (drawn by the creature scene's `Debug` node).
## Units: the strategy computes these and they are visualized as "speed-like" vectors.
var debug_seek: Vector2 = Vector2.ZERO
var debug_separation: Vector2 = Vector2.ZERO
var debug_avoidance: Vector2 = Vector2.ZERO
var debug_steering: Vector2 = Vector2.ZERO
var debug_final_velocity: Vector2 = Vector2.ZERO

@onready var visualRoot: = $Visuals
@onready var collisionShape: = $CollisionShape

## Cached obstacle-avoidance query (per creature so shared [MovementStrategy] resources stay thread-safe).
var _obstacle_avoid_query_params: PhysicsShapeQueryParameters2D
var _obstacle_avoid_rect_shape: RectangleShape2D

@onready var debug_root: Node2D = get_node_or_null("Debug")
var debug_speed_line: Line2D = null
var debug_separation_line: Line2D = null
var debug_avoidance_line: Line2D = null

func _ready() -> void:

	sensors_node = get_node("Sensors")
	ai_root = get_node("AI")
	movement = get_node("Movement")
	blackboard = Blackboard.new()
	if debug_root != null:
		debug_speed_line = debug_root.get_node_or_null("SpeedLine")
		debug_separation_line = debug_root.get_node_or_null("SeparationLine")
		debug_avoidance_line = debug_root.get_node_or_null("AvoidanceLine")
	health = max_health

	if creature_data != null:

		if !creature_data.can_fly:
			var mask_world = get_tree().current_scene.find_child("MaskWorld")
			alpha_mask = alpha_mask_scene.instantiate()
			alpha_mask.node = self
			mask_world.add_child(alpha_mask)

		if creature_data.taming_value_threshold > 0:
			blackboard.set_value(Blackboard.KEY_TAMED, false)
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

	needs_component = NeedsComponent.from_creature_data(creature_data)
	_initialize_hunger_need_starting_value()
	if needs_component != null and needs_component.has_any():
		SimulationSystem.register_needs(self, _on_needs_tick)

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
	if hunger_need.initial_value >= 0.0:
		return
	inst.set_value(randf_range(Blackboard.KEY_HUNGER_MAX * 0.8, Blackboard.KEY_HUNGER_MAX))


func _on_needs_tick(_node: Object, tick_delta: float) -> void:
	if needs_component != null:
		needs_component.update_all(self, tick_delta)


func get_need_value_or_null(id: StringName) -> Variant:
	if needs_component == null:
		return null
	if not needs_component.instances.has(id):
		return null
	return needs_component.get_need_value(id)


func get_need_value(id: StringName, default_value: float = 0.0) -> float:
	if needs_component == null:
		return default_value
	return needs_component.get_need_value(id, default_value)


func set_need_value(id: StringName, value: float) -> void:
	if needs_component != null:
		needs_component.set_need_value(id, value)


func _process(_delta: float) -> void:
	_update_visuals()
	_update_debug_visuals()

func _get_z_index() -> int:
	if creature_data.can_fly:
		return Constants.Z_INDEX_FLYING_CREATURES
	if is_big:
		return Constants.Z_INDEX_BIG_CREATURES
	else:
		return Constants.Z_INDEX_SMALL_CREATURES

func _physics_process(delta: float) -> void:
	# Clear debug values every physics tick so stale vectors don't linger.
	debug_seek = Vector2.ZERO
	debug_separation = Vector2.ZERO
	debug_avoidance = Vector2.ZERO
	debug_steering = Vector2.ZERO
	debug_final_velocity = Vector2.ZERO

	if creature_data != null:
		for goal in creature_data.goals:
			goal.update(self, delta)

	movement.update_movement(self, delta)

	move_and_slide()

func _update_visuals() -> void:
	visualRoot.rotation = virtual_rotation
	collisionShape.rotation = virtual_rotation

func _update_debug_visuals() -> void:

	if debug_root == null or not debug_root.visible:
		return

	_update_line_points(debug_speed_line, Vector2.ZERO, velocity)
	_update_line_points(debug_separation_line, Vector2.ZERO, debug_separation * 100)
	_update_line_points(debug_avoidance_line, Vector2.ZERO, debug_avoidance)

func _update_line_points(line: Line2D, start: Vector2, end: Vector2) -> void:
	if line == null:
		return
	var pts := PackedVector2Array()
	pts.push_back(start)
	pts.push_back(end)
	line.points = pts

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
