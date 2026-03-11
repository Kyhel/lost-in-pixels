extends CharacterBody2D

var base_speed = 200

const ATTACK_RANGE = 20 # fallback if no weapon equipped
const ATTACK_DAMAGE = 1 # fallback if no weapon equipped
const PICKUP_RADIUS = 16

var AttackEffectScene := preload("res://entities/attack_effect.tscn")
@export var weapon: WeaponData
var attack_cooldown_timer: float = 0.0

@onready var attack_hitbox: Area2D = $AttackHitbox

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

	try_pickup_items()

	var speed_modifier = ChunkManager.get_walk_speed_at_world_pos(global_position)

	velocity = dir.normalized() * base_speed * speed_modifier

	move_and_slide()

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


func try_pickup_items():
	for item in ObjectsManager.get_nearby_items(global_position, PICKUP_RADIUS):
		item.on_picked_up(self)
