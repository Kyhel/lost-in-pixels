class_name VegetationSpawnDefinition
extends Resource

enum PassType {
	BIG,
	SMALL,
	DECORATION,
}

@export var scene: PackedScene

@export var density: float  # probability per tile
@export var noise_scale: float
@export var min_spacing: int  # for large objects

@export var pass_type: PassType

@export var static_spawn_rules: Array[StaticVegetationSpawnRule]
