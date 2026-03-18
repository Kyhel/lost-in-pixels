extends Node

@export var player: Node2D

func _ready():
	pass

func _process(_delta: float):

	ChunkManager.update_chunks(player.global_position)
	EntitiesManager.update_entity_visibility(player.global_position)

func _physics_process(delta: float) -> void:
	EntitiesManager.update_entity_chunks(delta)
