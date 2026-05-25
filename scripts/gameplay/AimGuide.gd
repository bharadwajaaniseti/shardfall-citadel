class_name AimGuide
extends Node2D

@export var segment_count: int = 22
@export var segment_length: float = 20.0
@export var segment_gap: float = 9.0
@export var guide_width: float = 5.0
@export var max_aim_length: float = 560.0
@export var guide_color: Color = Color(0.62, 0.96, 1.0, 0.92)
@export var shadow_color: Color = Color(0.02, 0.08, 0.12, 0.78)

var _origin: Vector2 = Vector2.ZERO
var _direction: Vector2 = Vector2.UP
var _is_active: bool = false


func update_guide(origin: Vector2, direction: Vector2, is_active: bool) -> void:
	_origin = origin
	if direction.length_squared() > 0.001:
		_direction = direction.normalized()
	_is_active = is_active
	visible = is_active
	queue_redraw()


func _draw() -> void:
	if not _is_active:
		return

	var cursor_distance: float = 0.0
	var segment_index: int = 0
	while segment_index < segment_count and cursor_distance < max_aim_length:
		var segment_start: Vector2 = _origin + (_direction * cursor_distance)
		var capped_end_distance: float = minf(cursor_distance + segment_length, max_aim_length)
		var segment_end: Vector2 = _origin + (_direction * capped_end_distance)
		draw_line(segment_start, segment_end, shadow_color, guide_width + 5.0, true)
		draw_line(segment_start, segment_end, guide_color, guide_width, true)
		cursor_distance += segment_length + segment_gap
		segment_index += 1

	var end_point: Vector2 = _origin + (_direction * max_aim_length)
	var side_direction: Vector2 = _direction.orthogonal()
	var arrow_back: Vector2 = end_point - (_direction * 28.0)
	draw_line(arrow_back + (side_direction * 10.0), end_point, shadow_color, guide_width + 4.0, true)
	draw_line(arrow_back - (side_direction * 10.0), end_point, shadow_color, guide_width + 4.0, true)
	draw_line(arrow_back + (side_direction * 10.0), end_point, guide_color, guide_width, true)
	draw_line(arrow_back - (side_direction * 10.0), end_point, guide_color, guide_width, true)
