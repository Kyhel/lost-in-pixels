extends Node


signal world_reset

@export var player: Node2D

func _ready():
	SignalUtils.safe_connect(world_reset, ChunkManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, CreatureManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, ObjectsManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, VegetationManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, GameLog._on_world_reset)
	
	var spawn_system: SpawnSystem = get_node_or_null("SpawnSystem") as SpawnSystem
	if spawn_system != null:
		SignalUtils.safe_connect(ChunkManager.chunk_unloaded, spawn_system._on_chunk_unloaded)
		SignalUtils.safe_connect(world_reset, spawn_system._on_world_reset)


func reset_world_state() -> void:
	world_reset.emit()


func _process(_delta: float):

	ChunkManager.update_chunks(player.global_position)

func _physics_process(delta: float) -> void:
	CreatureManager.update_entity_chunks(delta)
	ObjectsManager.update_chunks(delta)
	VegetationManager.update_chunks(delta)
