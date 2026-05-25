class_name BreakableBlock
extends StaticBody2D

signal destroyed(block: BreakableBlock)

const FLASH_DURATION: float = 0.14
const PUNCH_DURATION: float = 0.11

@export var block_size: Vector2 = Vector2(104.0, 44.0)
@export var max_hp: int = 1

var current_hp: int = 1

var _visual: Polygon2D
var _border: Line2D
var _hp_label: Label
var _collision_shape: CollisionShape2D
var _base_color: Color = Color(0.22, 0.5, 0.78, 1.0)
var _flash_color: Color = Color(1.0, 0.95, 0.62, 1.0)
var _flash_remaining: float = 0.0
var _punch_remaining: float = 0.0


func _ready() -> void:
	add_to_group("blocks")
	if current_hp <= 0:
		current_hp = maxi(1, max_hp)
	_ensure_nodes()
	_update_visual()


func _process(delta: float) -> void:
	if _flash_remaining > 0.0:
		_flash_remaining = maxf(0.0, _flash_remaining - delta)
		var flash_weight: float = 1.0 - (_flash_remaining / FLASH_DURATION)
		if _visual != null:
			_visual.color = _flash_color.lerp(_base_color, flash_weight)

	if _punch_remaining > 0.0:
		_punch_remaining = maxf(0.0, _punch_remaining - delta)
		var punch_weight: float = _punch_remaining / PUNCH_DURATION
		scale = Vector2.ONE * (1.0 + (0.08 * punch_weight))
	else:
		scale = Vector2.ONE


func configure(hp: int, new_block_size: Vector2) -> void:
	max_hp = maxi(1, hp)
	current_hp = max_hp
	block_size = new_block_size
	_base_color = _color_for_hp(max_hp)

	if is_inside_tree():
		_ensure_nodes()
		_update_visual()


func apply_hit(damage: int = 1) -> void:
	if current_hp <= 0:
		return

	current_hp = maxi(0, current_hp - maxi(1, damage))
	_flash_remaining = FLASH_DURATION
	_punch_remaining = PUNCH_DURATION
	_update_visual()

	if current_hp <= 0:
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		destroyed.emit(self)
		queue_free()


func _ensure_nodes() -> void:
	if _visual == null:
		_visual = Polygon2D.new()
		add_child(_visual)

	if _border == null:
		_border = Line2D.new()
		_border.width = 3.0
		_border.default_color = Color(0.9, 0.95, 1.0, 0.9)
		add_child(_border)

	if _hp_label == null:
		_hp_label = Label.new()
		_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_hp_label.add_theme_font_size_override("font_size", 20)
		_hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		_hp_label.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.07, 1.0))
		_hp_label.add_theme_constant_override("outline_size", 4)
		add_child(_hp_label)

	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
		_collision_shape.shape = rectangle_shape
		add_child(_collision_shape)


func _update_visual() -> void:
	var half_size: Vector2 = block_size * 0.5
	var polygon_points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	var border_points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
		Vector2(-half_size.x, -half_size.y),
	])

	_visual.polygon = polygon_points
	if _flash_remaining <= 0.0:
		_visual.color = _base_color

	_border.points = border_points

	_hp_label.position = -half_size
	_hp_label.size = block_size
	_hp_label.text = str(current_hp)

	var rectangle_shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		rectangle_shape.size = block_size


func _color_for_hp(hp: int) -> Color:
	if hp <= 1:
		return Color(0.18, 0.57, 0.78, 1.0)
	if hp == 2:
		return Color(0.34, 0.47, 0.82, 1.0)
	if hp == 3:
		return Color(0.58, 0.36, 0.76, 1.0)
	return Color(0.78, 0.32, 0.42, 1.0)
