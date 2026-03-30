class_name Player
extends CharacterBody2D

var base_speed = 200

const ATTACK_RANGE = 20 # fallback if no weapon equipped
const ATTACK_DAMAGE = 1 # fallback if no weapon equipped
const PICKUP_RADIUS = 16
const FRONT_PICKUP_RADIUS = 22.0
const PICKUP_CONE_HALF_ANGLE := PI / 4.0

@export var attack_effect_scene : PackedScene
@export var weapon: WeaponData
var attack_cooldown_timer: float = 0.0

@export var max_hunger: float = 100.0
@export var hunger_decay_rate: float = 0.5 # per second
@export var hunger: float = max_hunger

@export var max_health: float = 100.0
@export var health: float = 100.0

@export var light_radius := 300
## World-space width of the transition band (shader softness). Outer edge of the veil is at `light_radius`.
@export var light_softness := 200.0

@export var edible_objects: Array[ObjectData] = []

var _dead: bool = false

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D

signal hunger_changed(hunger)
signal health_changed(health)
signal died()

func _ready() -> void:
	add_to_group(Constants.GROUP_PLAYER)
	_update_attack_hitbox_radius()
	z_index = Constants.Z_INDEX_PLAYER
	$Camera.zoom = Vector2.ONE * ConfigManager.config.camera_zoom_level

func _physics_process(delta):

	if _dead:
		return

	_apply_metabolic_drain(delta)

	if _dead:
		return

	var dir = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if Input.is_action_pressed("attack") and attack_cooldown_timer <= 0.0:
		attack()

	if Input.is_action_just_pressed("spawn_carrot"):
		_spawn_carrot()

	for abi in range(1, 11):
		if Input.is_action_just_pressed("ability_" + str(abi)):
			AbilityManager.try_activate_slot(abi - 1)

	if Input.is_action_just_pressed("interact"):
		try_pickup_in_front()

	if Input.is_action_just_pressed("interact_creature"):
		var target_creature: Creature = PlayerCreatureInteractionSystem.find_best_creature_target(self)
		if target_creature != null:
			PlayerCreatureInteractionSystem.begin_interaction(target_creature)

	var speed_modifier = ChunkManager.get_walk_speed_at_world_pos(global_position)

	velocity = dir.normalized() * base_speed * speed_modifier

	if not dir.is_zero_approx():
		# Base sprite orientation is up; rotate to face movement direction
		sprite.rotation = dir.angle() + TAU / 4.0  # TAU/4 = PI/2, maps up (0,-1) to 0

	move_and_slide()

	ChunkManager.reveal_around_player(global_position)

func _apply_metabolic_drain(delta: float) -> void:
	var drain := hunger_decay_rate * delta
	var remaining := drain
	if hunger > 0.0:
		var take := minf(hunger, remaining)
		hunger -= take
		remaining -= take
		hunger_changed.emit(hunger)
	if remaining > 0.0:
		var prev_health := health
		health = maxf(0.0, health - remaining)
		if health != prev_health:
			health_changed.emit(health)
		if health <= 0.0:
			_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	died.emit()

func is_dead() -> bool:
	return _dead

func take_damage(amount: int, source: Node = null) -> void:
	if _dead or amount <= 0:
		return
	var previous_health := health
	health = maxf(0.0, health - amount)
	if health != previous_health:
		health_changed.emit(health)
		EventManager.player_got_hit.emit(source, self, amount)
	if health <= 0.0:
		_die()

func _update_attack_hitbox_radius() -> void:
	if not is_node_ready() or attack_hitbox == null:
		return
	var radius: float = ATTACK_RANGE
	if weapon != null:
		radius = weapon.attack_range
	var shape: CircleShape2D = attack_hitbox.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = radius

## Approximate the player's collision "radius" based on its `CollisionShape2D`.
## Used for AI contact/approach logic (e.g. stop when the creature is close enough).
func get_hitbox_radius() -> float:

	var shape_radius: float = $CollisionShape2D.shape.radius

	var shape_scale: Vector2 = $CollisionShape2D.global_scale

	var max_scale := maxf(absf(shape_scale.x), absf(shape_scale.y))

	return shape_radius * max_scale

func attack():
	var attack_range: float = ATTACK_RANGE
	var damage: int = ATTACK_DAMAGE
	var cooldown: float = 0.3
	var effect_scene := attack_effect_scene

	if weapon != null:
		attack_range = weapon.attack_range
		damage = weapon.attack_damage
		cooldown = weapon.attack_cooldown
		if weapon.effect_scene != null:
			effect_scene = weapon.effect_scene

	_update_attack_hitbox_radius()

	for body in attack_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)

	attack_cooldown_timer = cooldown

	var fx = effect_scene.instantiate()
	fx.radius = attack_range
	add_child(fx)


func _spawn_carrot() -> void:
	var spawn_pos := global_position + Vector2(ChunkManager.TILE_SIZE, 0)
	ObjectsManager.spawn_object_at(ObjectDatabase.get_object_data(&"carrot"), spawn_pos)


func try_pickup_in_front() -> void:
	var forward := Vector2.UP.rotated(sprite.rotation)
	if forward.is_zero_approx():
		forward = Vector2.UP
	var cos_threshold: float = cos(PICKUP_CONE_HALF_ANGLE)
	var scored: Array[Dictionary] = []
	for wo in ObjectsManager.get_nearby_world_objects(global_position, FRONT_PICKUP_RADIUS):
		if not PickableBehavior.has_behavior(wo):
			continue
		var to_wo: Vector2 = wo.global_position - global_position
		var dist_sq: float = to_wo.length_squared()
		if dist_sq < 0.0001:
			scored.append({"world_object": wo, "dist_sq": dist_sq})
			continue
		var dir: Vector2 = to_wo / sqrt(dist_sq)
		if forward.dot(dir) >= cos_threshold:
			scored.append({"world_object": wo, "dist_sq": dist_sq})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["dist_sq"] as float) < (b["dist_sq"] as float)
	)

	for entry in scored:
		var it: WorldObject = entry["world_object"] as WorldObject
		if not is_instance_valid(it) or it.object_data == null:
			continue
		var food_val: float = float(PlayerEatableBehavior.get_food_value(it.object_data))
		if food_val > 0.0 and it.object_data in edible_objects:
			# Current interact behavior: choose Eat only when it would not overfill hunger.
			if hunger + food_val <= max_hunger or health < max_health:
				ObjectInteractionSystem.do_eat(self, it)
				break
			
		ObjectInteractionSystem.do_pickup(self, it)
		break
