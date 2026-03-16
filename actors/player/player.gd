extends CharacterBody2D

var base_speed = 200

const ATTACK_RANGE = 20 # fallback if no weapon equipped
const ATTACK_DAMAGE = 1 # fallback if no weapon equipped
const PICKUP_RADIUS = 16

var AttackEffectScene := preload("res://actors/player/attack_effect.tscn")
var carrot_data: ItemData = preload("res://data/items/carrot.tres") as ItemData
@export var weapon: WeaponData
var attack_cooldown_timer: float = 0.0

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_update_attack_hitbox_radius()

func _physics_process(delta):

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

	# try_pickup_items()

	var speed_modifier = ChunkManager.get_walk_speed_at_world_pos(global_position)

	velocity = dir.normalized() * base_speed * speed_modifier

	if not dir.is_zero_approx():
		# Base sprite orientation is up; rotate to face movement direction
		sprite.rotation = dir.angle() + TAU / 4.0  # TAU/4 = PI/2, maps up (0,-1) to 0

	move_and_slide()
	# PushPriorityHelper.push_away_overlapping(self, Creature.LAYER_SMALL_CREATURES)

	ChunkManager.reveal_around_player(global_position)

func _update_attack_hitbox_radius() -> void:
	if not is_node_ready() or attack_hitbox == null:
		return
	var radius: float = ATTACK_RANGE
	if weapon != null:
		radius = weapon.attack_range
	var shape: CircleShape2D = attack_hitbox.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = radius

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
		item.on_picked_up(self)
