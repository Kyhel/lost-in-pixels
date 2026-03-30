class_name SensorsRoot
extends Node

var creature: Creature

func _enter_tree() -> void:
	creature = get_parent() as Creature
	var sensors: Array[Sensor] = creature.creature_data.sensors if creature.creature_data != null else []
	SimulationSystem.register_sensor(
		self,
		func(_n: Object, _td: float) -> void:
			run_sensors(sensors)
	)


func run_sensors(sensors: Array[Sensor]) -> void:
	for sensor in sensors:
		sensor.update(self.get_parent())
