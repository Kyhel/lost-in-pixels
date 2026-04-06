class_name DayNightCycle
extends Node

@export var cycle_duration_seconds: float = 30.0
@export var world_canvas_modulate: CanvasModulate

@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var sunset_color: Color = Color(0.86, 0.68, 0.52, 1.0)
@export var night_color: Color = Color(0.42, 0.47, 0.62, 1.0)
@export var sunrise_color: Color = Color(0.80, 0.72, 0.62, 1.0)
@export var day_duration: float = 12.0
@export var sunset_duration: float = 3.0
@export var night_duration: float = 6.0
@export var sunrise_duration: float = 3.0

var _cycle_elapsed_seconds: float = 0.0


func _ready() -> void:
	_apply_current_color()


func _process(delta: float) -> void:
	if world_canvas_modulate == null:
		return
	if cycle_duration_seconds <= 0.0:
		world_canvas_modulate.color = day_color
		return

	_cycle_elapsed_seconds = fposmod(_cycle_elapsed_seconds + delta, cycle_duration_seconds)
	_apply_current_color()


func _apply_current_color() -> void:
	if world_canvas_modulate == null:
		return
	world_canvas_modulate.color = _color_at_phase(_phase())


func _phase() -> float:
	if cycle_duration_seconds <= 0.0:
		return 0.0
	return _cycle_elapsed_seconds / cycle_duration_seconds


func _color_at_phase(phase: float) -> Color:
	# day (constant) -> sunset (interpolate) -> night (constant) -> sunrise (interpolate)
	var total_phase_duration: float = _total_phase_duration()
	if total_phase_duration <= 0.0:
		return day_color

	var day_end: float = day_duration / total_phase_duration
	var sunset_end: float = day_end + (sunset_duration / total_phase_duration)
	var night_end: float = sunset_end + (night_duration / total_phase_duration)

	if phase < day_end:
		return day_color
	if phase < sunset_end:
		return _segment_color_with_mid(phase, day_end, sunset_end, day_color, sunset_color, night_color)
	if phase < night_end:
		return night_color
	return _segment_color_with_mid(phase, night_end, 1.0, night_color, sunrise_color, day_color)


func _total_phase_duration() -> float:
	return (
		maxf(day_duration, 0.0)
		+ maxf(sunset_duration, 0.0)
		+ maxf(night_duration, 0.0)
		+ maxf(sunrise_duration, 0.0)
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
