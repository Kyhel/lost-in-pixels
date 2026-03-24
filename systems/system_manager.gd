extends Node

@export var player: Node2D

func _ready():
	if not ChunkManager.chunk_unloaded.is_connected(CreatureManager._on_chunk_unloaded):
		ChunkManager.chunk_unloaded.connect(CreatureManager._on_chunk_unloaded)
	if not ChunkManager.chunk_unloaded.is_connected(ObjectsManager._on_chunk_unloaded):
		ChunkManager.chunk_unloaded.connect(ObjectsManager._on_chunk_unloaded)
	if not ChunkManager.chunk_unloaded.is_connected(VegetationManager._on_chunk_unloaded):
		ChunkManager.chunk_unloaded.connect(VegetationManager._on_chunk_unloaded)
	var spawn_system: SpawnSystem = get_node_or_null("SpawnSystem") as SpawnSystem
	if spawn_system != null and not ChunkManager.chunk_unloaded.is_connected(spawn_system._on_chunk_unloaded):
		ChunkManager.chunk_unloaded.connect(spawn_system._on_chunk_unloaded)


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
	CreatureManager.update_entity_visibility(player.global_position)

func _physics_process(delta: float) -> void:
	CreatureManager.update_entity_chunks(delta)
	ObjectsManager.update_chunks(delta)
	VegetationManager.update_chunks(delta)
