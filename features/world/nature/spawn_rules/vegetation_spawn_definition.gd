class_name VegetationSpawnDefinition
extends Resource

enum PassType {
	BIG,
	SMALL,
	DECORATION,
}

@export var object_data: ObjectData

@export var density := 0.1  # probability per tile
@export var noise_scale := 1.0
@export var min_spacing := 1  # for large objects

@export var pass_type: PassType

@export var static_spawn_rules: Array[StaticVegetationSpawnRule]
