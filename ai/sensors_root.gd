class_name SensorsRoot
extends Node

@export var update_interval := 0.2
var _sensor_elapsed := 0.0

var creature: Creature

func _ready() -> void:
	creature = get_parent()
	var phase: float = CreatureUtils.get_stagger_phase_offset(creature, update_interval)
	_sensor_elapsed = -phase

func update_sensors_2(delta: float, sensors: Array[Sensor]) -> void:

	if not _should_update(delta):
		return

	for sensor in sensors:
		sensor.update(self.get_parent())

func _should_update(delta: float) -> bool:
	if update_interval <= 0.0:
		return true
	_sensor_elapsed += delta
	if _sensor_elapsed < update_interval:
		return false
	_sensor_elapsed = fmod(_sensor_elapsed, update_interval)
	return true
