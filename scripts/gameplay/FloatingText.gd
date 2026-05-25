class_name FloatingText
extends Node2D

@export var lifetime: float = 0.65
@export var drift: Vector2 = Vector2(0.0, -54.0)

var _label: Label
var _age: float = 0.0
var _start_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_start_position = position


func configure(text: String, color: Color, font_size: int = 24, new_lifetime: float = 0.65, new_drift: Vector2 = Vector2(0.0, -54.0)) -> void:
	lifetime = maxf(0.05, new_lifetime)
	drift = new_drift

	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 1.0))
	_label.add_theme_constant_override("outline_size", 5)
	_label.size = Vector2(220.0, 56.0)
	_label.position = Vector2(-110.0, -28.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(delta: float) -> void:
	_age += delta
	var progress: float = clampf(_age / lifetime, 0.0, 1.0)
	position = _start_position + (drift * progress)
	scale = Vector2.ONE * lerpf(1.0, 0.9, progress)
	modulate.a = 1.0 - progress

	if _age >= lifetime:
		queue_free()
