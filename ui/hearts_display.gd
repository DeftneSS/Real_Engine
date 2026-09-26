class_name HeartsDisplay
extends Control
## Draws health as hearts; each heart is 2 health points (supports half hearts).

@export var heart_size: float = 36
@export var spacing: float = 8
@export var full_color: Color = Color(0.9, 0.1, 0.15)
@export var empty_color: Color = Color(0.2, 0.2, 0.2, 0.8)

const SEGMENTS: int = 32

var _current_health: int = 0
var _max_health: int = 0


func set_health(current_health: int, max_health: int) -> void:
	_current_health = current_health
	_max_health = max_health
	queue_redraw()


func _draw() -> void:
	var hearts: int = ceili(_max_health / 2.0)
	for i: int in hearts:
		var center: Vector2 = Vector2(i * (heart_size + spacing) + heart_size / 2, heart_size / 2)
		var filled: int = _current_health - i * 2
		draw_colored_polygon(_heart_points(center, 0, TAU, false), empty_color)
		if filled >= 2:
			draw_colored_polygon(_heart_points(center, 0, TAU, false), full_color)
		elif filled == 1:
			# t in [PI, TAU] traces the left half, closed along the vertical axis.
			draw_colored_polygon(_heart_points(center, PI, TAU, true), full_color)


func _heart_points(center: Vector2, from: float, to: float, include_end: bool) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var scale_factor: float = heart_size / 34.0
	var count: int = SEGMENTS + 1 if include_end else SEGMENTS
	for i: int in count:
		var t: float = lerpf(from, to, float(i) / SEGMENTS)
		var x: float = 16 * pow(sin(t), 3)
		var y: float = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		points.append(center + Vector2(x, y - 2.5) * scale_factor)
	return points
