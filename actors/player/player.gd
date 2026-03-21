class_name Player
extends CharacterBody2D

var base_speed = 200

const ATTACK_RANGE = 20 # fallback if no weapon equipped
const ATTACK_DAMAGE = 1 # fallback if no weapon equipped
const PICKUP_RADIUS = 16

var AttackEffectScene := preload("res://actors/player/attack_effect.tscn")
var carrot_data: ItemData = preload("res://data/items/carrot.tres") as ItemData
@export var weapon: WeaponData
var attack_cooldown_timer: float = 0.0

@export var max_hunger: float = 100.0
@export var hunger_decay_rate: float = 0.5 # per second
@export var hunger: float = max_hunger

@export var max_health: float = 100.0
@export var health: float = 100.0

var _dead: bool = false

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D

signal hunger_changed(hunger)
signal health_changed(health)
signal died()

func _ready() -> void:
	add_to_group("player")
	_update_attack_hitbox_radius()

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

	try_pickup_items()

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
	var effect_scene := AttackEffectScene

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
	var chunk := ChunkManager.get_chunk_from_position(spawn_pos)
	ObjectsManager.spawn_item_in_chunk(chunk, carrot_data, spawn_pos, 1)


func try_pickup_items():
	for item in ObjectsManager.get_nearby_items(global_position, PICKUP_RADIUS):
		if not item.item_data.can_pickup:
			continue
		item.on_picked_up(self)
		if item.item_data.player_food_value > 0:
			_apply_food_value(item.item_data.player_food_value)

func _apply_food_value(amount: float) -> void:
	if amount <= 0.0 or _dead:
		return
	var room := max_hunger - hunger
	var to_hunger := minf(amount, room)
	if to_hunger > 0.0:
		hunger += to_hunger
		hunger_changed.emit(hunger)
	var overflow := amount - to_hunger
	if overflow > 0.0:
		var prev_health := health
		health = minf(max_health, health + overflow)
		if health != prev_health:
			health_changed.emit(health)
