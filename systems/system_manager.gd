extends Node


signal world_reset(clear_fog_memory: bool)

@export var player: Node2D

func _ready():
	SignalUtils.safe_connect(world_reset, ChunkManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, CreatureManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, ObjectsManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, VegetationManager._on_world_reset)

	var spawn_system: SpawnSystem = get_node_or_null("SpawnSystem") as SpawnSystem
	if spawn_system != null:
		SignalUtils.safe_connect(ChunkManager.chunk_unloaded, spawn_system._on_chunk_unloaded)
		SignalUtils.safe_connect(world_reset, spawn_system._on_world_reset)


func reset_world_state(clear_fog_memory: bool = true) -> void:
	world_reset.emit(clear_fog_memory)


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

func _physics_process(delta: float) -> void:
	CreatureManager.update_entity_chunks(delta)
	ObjectsManager.update_chunks(delta)
	VegetationManager.update_chunks(delta)
