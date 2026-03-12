class_name SensorsRoot
extends Node


@export var update_interval := 0.2
var timer := 0.0

func update_sensors(delta: float) -> void:

	timer -= delta
	if timer > 0:
		return

	timer = update_interval

	for sensor in get_children():
		if sensor is Sensor:
			sensor.update(self.get_parent())
