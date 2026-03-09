extends CharacterBody2D

var speed = 200

@onready var chunk_manager = get_node("../../World/ChunkManager")

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

	velocity = dir.normalized() * speed

	move_and_slide()

	chunk_manager.reveal_around_player(global_position)
