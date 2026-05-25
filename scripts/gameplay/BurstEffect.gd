class_name BurstEffect
extends Node2D

@export var lifetime: float = 0.42
@export var burst_radius: float = 56.0
@export var burst_color: Color = Color(1.0, 0.82, 0.35, 1.0)

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(_age / lifetime, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	var color: Color = Color(burst_color.r, burst_color.g, burst_color.b, alpha)
	var inner_radius: float = lerpf(4.0, 18.0, progress)
	var outer_radius: float = lerpf(18.0, burst_radius, progress)
	var ray_count: int = 10

	for index in range(ray_count):
		var angle: float = (TAU / float(ray_count)) * float(index)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(direction * inner_radius, direction * outer_radius, color, 3.0, true)

	draw_circle(Vector2.ZERO, lerpf(12.0, 4.0, progress), Color(burst_color.r, burst_color.g, burst_color.b, alpha * 0.35))
