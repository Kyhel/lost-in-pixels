extends Node


signal world_reset

@export var player: Node2D

func _ready():
	SignalUtils.safe_connect(world_reset, ChunkManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, CreatureManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, ObjectsManager._on_world_reset)
	SignalUtils.safe_connect(world_reset, GameLog._on_world_reset)
	SignalUtils.safe_connect(world_reset, SimulationSystem._on_world_reset)
	

func reset_world_state() -> void:
	world_reset.emit()


func _process(_delta: float):

	ChunkManager.update_chunks(player.global_position)

func _physics_process(delta: float) -> void:
	CreatureManager.update_entity_chunks(delta)
	ObjectsManager.update_chunks(delta)
