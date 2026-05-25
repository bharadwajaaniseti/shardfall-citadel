class_name Ball
extends CharacterBody2D

signal returned(ball: Ball)
signal block_hit(block: BreakableBlock, damage: int)
signal impact(world_position: Vector2)

@export var speed: float = 840.0
@export var radius: float = 12.0
@export var ball_color: Color = Color(0.86, 0.96, 1.0, 1.0)
@export var max_lifetime: float = 18.0
@export var min_axis_ratio: float = 0.17
@export var trail_point_limit: int = 14

var damage: int = 1
var return_line_y: float = 1040.0
var is_active: bool = false

var _collision_shape: CollisionShape2D
var _age: float = 0.0
var _trail_points: Array[Vector2] = []


func _ready() -> void:
	add_to_group("balls")
	_ensure_collision_shape()
	queue_redraw()


func configure(new_return_line_y: float, new_damage: int) -> void:
	return_line_y = new_return_line_y
	damage = maxi(1, new_damage)


func launch(direction: Vector2) -> void:
	var launch_direction: Vector2 = direction
	if launch_direction.length_squared() <= 0.001:
		launch_direction = Vector2.UP
	if launch_direction.y > -0.05:
		launch_direction.y = -absf(launch_direction.y) - 0.2

	velocity = launch_direction.normalized() * speed
	is_active = true
	_age = 0.0
	_trail_points.clear()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	_age += delta
	_record_trail_point()

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)

	if global_position.y > return_line_y or _age >= max_lifetime:
		_return_to_cannon()

	queue_redraw()


func _draw() -> void:
	_draw_trail()
	draw_circle(Vector2.ZERO, radius + 11.0, Color(0.32, 0.78, 1.0, 0.16))
	draw_circle(Vector2.ZERO, radius + 6.0, Color(0.46, 0.9, 1.0, 0.22))
	draw_circle(Vector2.ZERO, radius, ball_color)
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 24, Color(0.35, 0.75, 1.0, 1.0), 2.0, true)


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	var impact_position: Vector2 = collision.get_position()

	if collider is BreakableBlock:
		var block: BreakableBlock = collider as BreakableBlock
		block.apply_hit(damage)
		block_hit.emit(block, damage)

	impact.emit(impact_position)
	velocity = _stabilize_velocity(velocity.bounce(collision.get_normal()))
	global_position += collision.get_normal()


func _return_to_cannon() -> void:
	is_active = false
	returned.emit(self)
	queue_free()


func _ensure_collision_shape() -> void:
	if _collision_shape != null:
		return

	_collision_shape = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = radius
	_collision_shape.shape = circle_shape
	add_child(_collision_shape)


func _record_trail_point() -> void:
	_trail_points.append(global_position)
	while _trail_points.size() > trail_point_limit:
		_trail_points.remove_at(0)


func _draw_trail() -> void:
	var point_count: int = _trail_points.size()
	if point_count < 2:
		return

	var previous_point: Vector2 = to_local(_trail_points[0])
	for index in range(1, point_count):
		var progress: float = float(index) / float(point_count)
		var current_point: Vector2 = to_local(_trail_points[index])
		var width: float = lerpf(2.0, radius * 1.35, progress)
		var alpha: float = lerpf(0.05, 0.42, progress)
		draw_line(previous_point, current_point, Color(0.46, 0.9, 1.0, alpha), width, true)
		previous_point = current_point


func _stabilize_velocity(candidate_velocity: Vector2) -> Vector2:
	var current_speed: float = maxf(speed, candidate_velocity.length())
	var direction: Vector2 = candidate_velocity.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.UP

	var min_component: float = clampf(min_axis_ratio, 0.05, 0.45)
	if absf(direction.y) < min_component:
		direction.y = _component_with_minimum(direction.y, -1.0 if velocity.y <= 0.0 else 1.0, min_component)

	return direction.normalized() * current_speed


func _component_with_minimum(value: float, fallback_sign: float, minimum: float) -> float:
	var sign_value: float = fallback_sign
	if value > 0.0:
		sign_value = 1.0
	elif value < 0.0:
		sign_value = -1.0
	return sign_value * minimum
