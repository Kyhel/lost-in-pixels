class_name ObjectData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var texture: Texture2D
@export var scene: PackedScene

## World pickup radius (pixels); drives [WorldObject] sprite and collision scale (base circle radius 1 in scene).
@export var hitbox_radius: float = 4.0

@export var spawn_definition: SpawnDefinition

@export var features: Array[WorldObjectFeature] = []
@export var behaviors: Array[WorldObjectBehavior] = []
