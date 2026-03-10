extends Node

@onready var player = get_node("../../Entities/Player")

func _ready():
	pass

func _process(delta):

	ChunkManager.update_chunks(player.global_position)
	EntitiesManager.update_entity_visibility(player.global_position)
