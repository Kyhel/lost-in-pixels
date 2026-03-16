extends Node

@export var player: Node2D

func _ready():
	pass

func _process(delta: float):

	ChunkManager.update_chunks(player.global_position)
	EntitiesManager.update_entity_visibility(player.global_position)
	# SpawnManager.update_chunks(delta)
