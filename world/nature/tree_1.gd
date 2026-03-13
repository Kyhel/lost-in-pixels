extends Node2D

@onready var foliage := $Foliage
@onready var area := $Area2D

var player_inside := false
var player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta):
	if player_inside and player:
		foliage.material.set_shader_parameter("player_pos", player.global_position)
	else:
		foliage.material.set_shader_parameter("player_pos", Vector2(99999,99999))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
