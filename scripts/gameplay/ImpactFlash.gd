class_name ImpactFlash
extends Node2D

@export var lifetime: float = 0.16
@export var max_radius: float = 34.0
@export var flash_color: Color = Color(1.0, 0.92, 0.55, 1.0)

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
	var radius: float = lerpf(8.0, max_radius, progress)
	var line_color: Color = Color(flash_color.r, flash_color.g, flash_color.b, alpha)
	var fill_color: Color = Color(flash_color.r, flash_color.g, flash_color.b, alpha * 0.22)

	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, line_color, 3.0, true)
