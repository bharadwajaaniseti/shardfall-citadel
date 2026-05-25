class_name Cannon
extends Node2D

@export var barrel_length: float = 72.0
@export var base_radius: float = 34.0
@export var min_upward_aim: float = -24.0

var _aim_direction: Vector2 = Vector2.UP


func set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	_aim_direction = direction.normalized()
	queue_redraw()


func get_aim_direction(mouse_global_position: Vector2) -> Vector2:
	var raw_direction: Vector2 = mouse_global_position - global_position
	if raw_direction.length_squared() <= 0.001:
		return _aim_direction

	if raw_direction.y > min_upward_aim:
		raw_direction.y = min_upward_aim

	return raw_direction.normalized()


func get_muzzle_global_position() -> Vector2:
	return global_position + (_aim_direction * barrel_length)


func _draw() -> void:
	draw_circle(Vector2.ZERO, base_radius, Color(0.17, 0.19, 0.23, 1.0))
	draw_circle(Vector2.ZERO, base_radius - 8.0, Color(0.34, 0.39, 0.47, 1.0))
	draw_line(Vector2.ZERO, _aim_direction * barrel_length, Color(0.82, 0.88, 0.92, 1.0), 18.0, true)
	draw_circle(_aim_direction * barrel_length, 12.0, Color(0.94, 0.98, 1.0, 1.0))
