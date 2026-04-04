class_name PlayerConfig
extends Resource

@export var attack_effect_scene: PackedScene

@export var max_hunger: float = 100.0
@export var hunger_decay_rate: float = 0.5 # per second

@export var max_health: float = 100.0

@export var light_radius := 300
## World-space width of the transition band (shader softness). Outer edge of the veil is at `light_radius`.
@export var light_softness := 200.0
