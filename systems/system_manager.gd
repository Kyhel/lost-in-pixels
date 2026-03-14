extends Node

@onready var player = get_node("../../Entities/Player")

var spawn_timer: float = 0.0
const SPAWN_INTERVAL = 5.0

func _ready():
	pass

func _process(delta):

	ChunkManager.update_chunks(player.global_position)
	EntitiesManager.update_entity_visibility(player.global_position)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = SPAWN_INTERVAL
		SpawnManager.update_chunks()
