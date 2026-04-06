extends Node

var _world_canvas_modulate: CanvasModulate

var _cycle_elapsed_seconds: float = 0.0

var _config: DayNightCycleConfig

enum CyclePhase {
	DAY,
	SUNSET,
	NIGHT,
	SUNRISE,
}

signal phase_changed(phase: CyclePhase)

var current_phase: CyclePhase = CyclePhase.DAY


func is_night_phase() -> bool:
	return current_phase == CyclePhase.NIGHT


func _set_phase(new_phase: CyclePhase) -> void:
	if new_phase == current_phase:
		return
	current_phase = new_phase
	phase_changed.emit(current_phase)

func _ellapsed_seconds_to_phase(ellapsed_seconds: float) -> CyclePhase:

	var ellapsed_time = ellapsed_seconds / _config.cycle_duration_seconds * _total_phase_duration()

	if ellapsed_time < _config.day_duration:
		return CyclePhase.DAY
	if ellapsed_time < _config.day_duration + _config.sunset_duration:
		return CyclePhase.SUNSET
	if ellapsed_time < _config.day_duration + _config.sunset_duration + _config.night_duration:
		return CyclePhase.NIGHT
	return CyclePhase.SUNRISE


func is_player_light_visible() -> bool:
	if _config == null or _config.cycle_duration_seconds <= 0.0:
		return false
	var ellapsed_time: float = (
		_cycle_elapsed_seconds / _config.cycle_duration_seconds * _total_phase_duration()
	)
	var on_from: float = _config.day_duration + _config.sunset_duration * 0.5
	var on_until: float = (
		_config.day_duration
		+ _config.sunset_duration
		+ _config.night_duration
		+ _config.sunrise_duration * 0.5
	)
	return ellapsed_time >= on_from and ellapsed_time < on_until


func _ready() -> void:
	_config = ConfigManager.get_day_night_cycle_config()
	if _config == null:
		push_error("DayNightCycle: DayNightCycleConfig is missing. Configure it in the main config.")
		set_process(false)
		return

	_resolve_world_canvas_modulate()
	_apply_current_color()
	if _config.cycle_duration_seconds <= 0.0:
		_set_phase(CyclePhase.DAY)
	else:
		_set_phase(_ellapsed_seconds_to_phase(_cycle_elapsed_seconds))


func _process(delta: float) -> void:
	if _world_canvas_modulate == null:
		_resolve_world_canvas_modulate()
	if _world_canvas_modulate == null:
		return
	if _config.cycle_duration_seconds <= 0.0:
		_world_canvas_modulate.color = _config.day_color
		_set_phase(CyclePhase.DAY)
		return

	if ConfigManager.config != null and not ConfigManager.config.day_night_cycle_enabled:
		_cycle_elapsed_seconds = 0.0
		_apply_current_color()
		_set_phase(_ellapsed_seconds_to_phase(_cycle_elapsed_seconds))
		return

	_cycle_elapsed_seconds = fposmod(_cycle_elapsed_seconds + delta, _config.cycle_duration_seconds)
	_apply_current_color()
	_set_phase(_ellapsed_seconds_to_phase(_cycle_elapsed_seconds))


func _apply_current_color() -> void:
	if _world_canvas_modulate == null:
		return
	_world_canvas_modulate.color = _color_at_phase(_phase())


func _phase() -> float:
	if _config.cycle_duration_seconds <= 0.0:
		return 0.0
	return _cycle_elapsed_seconds / _config.cycle_duration_seconds


func _night_phase_bounds() -> Vector2:
	var total_phase_duration: float = _total_phase_duration()
	if total_phase_duration <= 0.0:
		return Vector2.ZERO

	var day_end: float = _config.day_duration / total_phase_duration
	var sunset_end: float = day_end + (_config.sunset_duration / total_phase_duration)
	var night_end: float = sunset_end + (_config.night_duration / total_phase_duration)
	return Vector2(sunset_end, night_end)


func _color_at_phase(phase: float) -> Color:
	# day (constant) -> sunset (interpolate) -> night (constant) -> sunrise (interpolate)
	var total_phase_duration: float = _total_phase_duration()
	if total_phase_duration <= 0.0:
		return _config.day_color

	var day_end: float = _config.day_duration / total_phase_duration
	var sunset_end: float = day_end + (_config.sunset_duration / total_phase_duration)
	var night_end: float = sunset_end + (_config.night_duration / total_phase_duration)

	if phase < day_end:
		return _config.day_color
	if phase < sunset_end:
		return _segment_color_with_mid(
			phase,
			day_end,
			sunset_end,
			_config.day_color,
			_config.sunset_color,
			_config.night_color
		)
	if phase < night_end:
		return _config.night_color
	return _segment_color_with_mid(
		phase,
		night_end,
		1.0,
		_config.night_color,
		_config.sunrise_color,
		_config.day_color
	)


func _total_phase_duration() -> float:
	return (
		maxf(_config.day_duration, 0.0)
		+ maxf(_config.sunset_duration, 0.0)
		+ maxf(_config.night_duration, 0.0)
		+ maxf(_config.sunrise_duration, 0.0)
	)


func _segment_color(phase: float, start: float, finish: float, from: Color, to: Color) -> Color:
	if finish <= start:
		return to
	var t: float = clampf((phase - start) / (finish - start), 0.0, 1.0)
	return from.lerp(to, t)


func _segment_color_with_mid(
	phase: float, start: float, finish: float, from: Color, mid: Color, to: Color
) -> Color:
	if finish <= start:
		return to

	var t: float = clampf((phase - start) / (finish - start), 0.0, 1.0)
	if t < 0.5:
		return from.lerp(mid, t * 2.0)
	return mid.lerp(to, (t - 0.5) * 2.0)


func _resolve_world_canvas_modulate() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var world_canvas_modulate_path: NodePath = _config.world_canvas_modulate_path
	_world_canvas_modulate = current_scene.get_node_or_null(world_canvas_modulate_path) as CanvasModulate
