class_name SignalUtils

static func safe_connect(source_signal: Signal, target: Callable) -> void:
	if not source_signal.is_connected(target):
		source_signal.connect(target)
