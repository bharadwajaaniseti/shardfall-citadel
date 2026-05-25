class_name Ball
extends CharacterBody2D

signal returned(ball: Ball)
signal block_hit(block: BreakableBlock, damage: int)
signal impact(world_position: Vector2)
signal chain_requested(ball: Ball, source_block: BreakableBlock, chain_range: float, chain_damage: int)
signal split_requested(ball: Ball, split_count: int, damage_multiplier: float)
signal feedback_requested(text: String, world_position: Vector2, color: Color)

const WALL_MASK: int = 1
const BLOCK_MASK: int = 2
const ACTIVE_COLLISION_MASK: int = WALL_MASK | BLOCK_MASK

@export var speed: float = 840.0
@export var radius: float = 12.0
@export var ball_color: Color = Color(0.86, 0.96, 1.0, 1.0)
@export var max_lifetime: float = 18.0
@export var min_axis_ratio: float = 0.17
@export var trail_point_limit: int = 14
@export var min_speed: float = 520.0
@export var max_speed: float = 1180.0

var ball_id: StringName = StringName("basic_orb")
var display_name: String = "Basic Orb"
var damage: int = 1
var behaviour_type: StringName = StringName("basic")
var parameters: Dictionary = {}
var bounce_count: int = 0
var has_split: bool = false
var pierce_remaining: int = 0
var return_line_y: float = 1040.0
var is_active: bool = false
var controller: Node = null
var void_pull_resistance: float = 1.0

var _collision_shape: CollisionShape2D
var _age: float = 0.0
var _trail_points: Array[Vector2] = []
var _trail_color: Color = Color(0.46, 0.9, 1.0, 1.0)
var _definition_snapshot: Dictionary = {}
var _block_collision_disabled_time: float = 0.0


func _ready() -> void:
	add_to_group("balls")
	collision_layer = 4
	collision_mask = ACTIVE_COLLISION_MASK
	_ensure_collision_shape()
	queue_redraw()


func setup_from_definition(definition: Dictionary) -> void:
	_definition_snapshot = definition.duplicate(true)
	ball_id = StringName(String(definition.get("id", "basic_orb")))
	display_name = String(definition.get("display_name", "Basic Orb"))
	damage = maxi(1, int(definition.get("base_damage", definition.get("damage", 1))))
	speed = maxf(1.0, float(definition.get("speed", 840.0)))
	radius = maxf(4.0, float(definition.get("radius", 12.0)))
	behaviour_type = StringName(String(definition.get("behaviour_type", "basic")))

	var color_value: Variant = definition.get("color", "#dfffe8")
	ball_color = Color.from_string(String(color_value), Color(0.86, 0.96, 1.0, 1.0))
	_trail_color = ball_color

	var parameters_value: Variant = definition.get("parameters", {})
	parameters = {}
	if parameters_value is Dictionary:
		parameters = (parameters_value as Dictionary).duplicate(true)

	pierce_remaining = int(parameters.get("pierce_count", 0))
	void_pull_resistance = clampf(float(parameters.get("void_pull_resistance", 1.0)), 0.0, 1.0)
	min_speed = minf(min_speed, speed * 0.85)
	max_speed = maxf(max_speed, speed * 1.35)
	_sync_collision_shape()


func configure(new_return_line_y: float, damage_override: int = 0) -> void:
	return_line_y = new_return_line_y
	if damage_override > 0:
		damage = damage_override


func launch(direction: Vector2) -> void:
	var launch_direction: Vector2 = direction
	if launch_direction.length_squared() <= 0.001:
		launch_direction = Vector2.UP
	if launch_direction.y > -0.05:
		launch_direction.y = -absf(launch_direction.y) - 0.2

	velocity = _clamp_velocity_speed(launch_direction.normalized() * speed)
	is_active = true
	_age = 0.0
	bounce_count = 0
	_trail_points.clear()


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	_age += delta
	_update_temporary_collision_mask(delta)
	_record_trail_point()
	velocity = _clamp_velocity_speed(velocity)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)

	if global_position.y > return_line_y or _age >= max_lifetime:
		_return_to_cannon()

	queue_redraw()


func _draw() -> void:
	_draw_trail()
	draw_circle(Vector2.ZERO, radius + 11.0, Color(ball_color.r, ball_color.g, ball_color.b, 0.16))
	draw_circle(Vector2.ZERO, radius + 6.0, Color(ball_color.r, ball_color.g, ball_color.b, 0.24))
	draw_circle(Vector2.ZERO, radius, ball_color)
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.82), 2.0, true)


func apply_ball_behaviour_on_block_hit(block: Node) -> void:
	if not (block is BreakableBlock):
		return

	var target_block: BreakableBlock = block as BreakableBlock
	match String(behaviour_type):
		"heavy":
			feedback_requested.emit("HEAVY", target_block.global_position + Vector2(0.0, -58.0), ball_color)
		"ember":
			var burn_damage: int = int(parameters.get("burn_damage", 1))
			var burn_ticks: int = int(parameters.get("burn_ticks", 2))
			target_block.apply_burn(burn_damage, burn_ticks)
			feedback_requested.emit("BURN", target_block.global_position + Vector2(0.0, -58.0), ball_color)
		"frost":
			var chill_duration: float = float(parameters.get("chill_duration", 3.0))
			var bonus_multiplier: float = float(parameters.get("freeze_bonus_multiplier", 1.75))
			target_block.apply_chill(chill_duration, bonus_multiplier)
			feedback_requested.emit("CHILL", target_block.global_position + Vector2(0.0, -58.0), ball_color)
		"spark":
			var chain_chance: float = clampf(float(parameters.get("chain_chance", 0.45)), 0.0, 1.0)
			var roll: float = randf()
			if roll <= chain_chance:
				var chain_range: float = float(parameters.get("chain_range", 150.0))
				var chain_damage: int = int(parameters.get("chain_damage", 1))
				chain_requested.emit(self, target_block, chain_range, chain_damage)


func apply_speed_boost(multiplier: float, boost_max_speed: float = 1180.0) -> void:
	var safe_multiplier: float = maxf(1.0, multiplier)
	var allowed_max_speed: float = maxf(min_speed, boost_max_speed)
	var boosted_speed: float = minf(allowed_max_speed, velocity.length() * safe_multiplier)
	if velocity.length_squared() <= 0.001:
		velocity = Vector2.UP * boosted_speed
	else:
		velocity = velocity.normalized() * boosted_speed


func apply_attraction(target_position: Vector2, strength: float, delta: float) -> void:
	if not is_active or strength <= 0.0 or void_pull_resistance <= 0.0:
		return

	var pull_direction: Vector2 = target_position - global_position
	if pull_direction.length_squared() <= 0.001:
		return

	velocity += pull_direction.normalized() * strength * void_pull_resistance * delta
	velocity = _clamp_velocity_speed(velocity)


func clamp_speed() -> void:
	velocity = _clamp_velocity_speed(velocity)


func get_definition_snapshot() -> Dictionary:
	return _definition_snapshot.duplicate(true)


func mark_as_split_child(damage_multiplier: float) -> void:
	has_split = true
	pierce_remaining = 0
	damage = maxi(1, floori(float(damage) * damage_multiplier))
	radius = maxf(7.0, radius * 0.75)
	_sync_collision_shape()
	queue_redraw()


func disable_block_collision_briefly(duration: float) -> void:
	_block_collision_disabled_time = maxf(_block_collision_disabled_time, duration)
	collision_mask = WALL_MASK


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	var impact_position: Vector2 = collision.get_position()

	if collider is BreakableBlock:
		var block: BreakableBlock = collider as BreakableBlock
		var damage_taken: int = block.take_damage(damage, impact_position, self)
		block_hit.emit(block, damage_taken)
		apply_ball_behaviour_on_block_hit(block)

		if _try_pierce_block():
			impact.emit(impact_position)
			global_position += velocity.normalized() * (radius * 2.5)
			return

	impact.emit(impact_position)
	velocity = _stabilize_velocity(velocity.bounce(collision.get_normal()))
	bounce_count += 1
	_try_split()
	global_position += collision.get_normal()


func _try_pierce_block() -> bool:
	if String(behaviour_type) != "drill" or pierce_remaining <= 0:
		return false

	pierce_remaining -= 1
	_block_collision_disabled_time = 0.08
	collision_mask = WALL_MASK
	feedback_requested.emit("PIERCE", global_position + Vector2(0.0, -32.0), ball_color)
	return true


func _try_split() -> void:
	if String(behaviour_type) != "split" or has_split:
		return

	var split_after_bounces: int = int(parameters.get("split_after_bounces", 3))
	if bounce_count < split_after_bounces:
		return

	has_split = true
	var split_count: int = maxi(1, int(parameters.get("split_count", 2)))
	var damage_multiplier: float = float(parameters.get("split_damage_multiplier", 0.65))
	feedback_requested.emit("SPLIT", global_position + Vector2(0.0, -32.0), ball_color)
	split_requested.emit(self, split_count, damage_multiplier)


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


func _sync_collision_shape() -> void:
	if _collision_shape == null:
		return

	var circle_shape: CircleShape2D = _collision_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = radius


func _update_temporary_collision_mask(delta: float) -> void:
	if _block_collision_disabled_time <= 0.0:
		collision_mask = ACTIVE_COLLISION_MASK
		return

	_block_collision_disabled_time = maxf(0.0, _block_collision_disabled_time - delta)
	if _block_collision_disabled_time <= 0.0:
		collision_mask = ACTIVE_COLLISION_MASK


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
		draw_line(previous_point, current_point, Color(_trail_color.r, _trail_color.g, _trail_color.b, alpha), width, true)
		previous_point = current_point


func _stabilize_velocity(candidate_velocity: Vector2) -> Vector2:
	var current_speed: float = clampf(candidate_velocity.length(), min_speed, max_speed)
	var direction: Vector2 = candidate_velocity.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.UP

	var min_component: float = clampf(min_axis_ratio, 0.05, 0.45)
	if absf(direction.y) < min_component:
		direction.y = _component_with_minimum(direction.y, -1.0 if direction.y < 0.0 else 1.0, min_component)

	return direction.normalized() * current_speed


func _clamp_velocity_speed(candidate_velocity: Vector2) -> Vector2:
	var current_length: float = candidate_velocity.length()
	if current_length <= 0.001:
		return Vector2.UP * min_speed

	return candidate_velocity.normalized() * clampf(current_length, min_speed, max_speed)


func _component_with_minimum(value: float, fallback_sign: float, minimum: float) -> float:
	var sign_value: float = fallback_sign
	if value > 0.0:
		sign_value = 1.0
	elif value < 0.0:
		sign_value = -1.0
	return sign_value * minimum
