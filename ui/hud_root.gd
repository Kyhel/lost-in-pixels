extends Control

@export var player: Player

@onready var hunger_bar = $HungerBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	player.hunger_changed.connect(self._on_hunger_changed)
		
	# Initialize the bar
	hunger_bar.min_value = 0
	hunger_bar.max_value = player.max_hunger
	hunger_bar.value = player.hunger


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_hunger_changed(hunger: float):
	hunger_bar.value = hunger
