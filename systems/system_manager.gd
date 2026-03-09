extends Node

@onready var chunk_manager = get_node("../../World/ChunkManager")
@onready var player = get_node("../../Entities/Player")

func _ready():
	pass

func _process(delta):

	chunk_manager.update_chunks(player.global_position)
