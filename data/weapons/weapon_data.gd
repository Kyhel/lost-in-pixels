extends Resource
class_name WeaponData

@export var id: StringName
@export var display_name: String = ""

@export var attack_range: float = 20.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.3

# Optional custom visual/effect for this weapon's attack.
@export var effect_scene: PackedScene
