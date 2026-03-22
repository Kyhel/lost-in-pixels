extends Node

@export var player: Node2D

func _ready():
	pass


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("pause_menu"):
		var scene := get_tree().current_scene
		if scene:
			var pm := scene.find_child("PauseMenuRoot", true, false)
			if pm and pm.has_method("toggle_pause_menu"):
				pm.toggle_pause_menu()
				get_viewport().set_input_as_handled()


func _process(_delta: float):

	ChunkManager.update_chunks(player.global_position)
	EntitiesManager.update_entity_visibility(player.global_position)

func _physics_process(delta: float) -> void:
	EntitiesManager.update_entity_chunks(delta)
	ObjectsManager.update_chunks(delta)
