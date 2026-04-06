class_name DayNightCycleConfig
extends Resource

@export var world_canvas_modulate_path: NodePath = ^"WorldCanvasModulate"

@export var cycle_duration_seconds: float = 30.0

@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var sunset_color: Color = Color(0.86, 0.68, 0.52, 1.0)
@export var night_color: Color = Color(0.42, 0.47, 0.62, 1.0)
@export var sunrise_color: Color = Color(0.80, 0.72, 0.62, 1.0)

@export var day_duration: float = 12.0
@export var sunset_duration: float = 3.0
@export var night_duration: float = 6.0
@export var sunrise_duration: float = 3.0
