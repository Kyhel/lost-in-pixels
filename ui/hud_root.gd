extends Control

@export var player: Player

@onready var health_bar = $HealthBar
@onready var hunger_bar = $HungerBar

func _ready() -> void:
	player.hunger_changed.connect(_on_hunger_changed)
	player.health_changed.connect(_on_health_changed)

	health_bar.min_value = 0
	health_bar.max_value = player.max_health
	health_bar.value = player.health

	hunger_bar.min_value = 0
	hunger_bar.max_value = player.max_hunger
	hunger_bar.value = player.hunger


func _on_hunger_changed(hunger: float) -> void:
	hunger_bar.value = hunger


func _on_health_changed(p_health: float) -> void:
	health_bar.value = p_health
