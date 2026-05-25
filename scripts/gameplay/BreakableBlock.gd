class_name BreakableBlock
extends StaticBody2D

signal hit(block: BreakableBlock, damage_taken: int, hit_position: Vector2, source_ball: Node)
signal destroyed(block: BreakableBlock, hit_position: Vector2, source_ball: Node)
signal special_effect_requested(block: BreakableBlock, effect_id: StringName, world_position: Vector2, parameters: Dictionary, source_ball: Node)

const FLASH_DURATION: float = 0.14
const PUNCH_DURATION: float = 0.11
const BURN_TICK_INTERVAL: float = 0.45

@export var block_size: Vector2 = Vector2(104.0, 44.0)
@export var max_hp: int = 1

var block_id: StringName = StringName("basic_block")
var display_name: String = "Basic Block"
var current_hp: int = 1
var block_color: Color = Color(0.18, 0.57, 0.78, 1.0)
var behaviour_type: StringName = StringName("basic")
var parameters: Dictionary = {}

var _visual: Polygon2D
var _border: Line2D
var _hp_label: Label
var _collision_shape: CollisionShape2D
var _base_color: Color = Color(0.18, 0.57, 0.78, 1.0)
var _active_flash_color: Color = Color(1.0, 0.95, 0.62, 1.0)
var _flash_remaining: float = 0.0
var _punch_remaining: float = 0.0
var _is_destroyed: bool = false
var _armour_source_ids: Dictionary = {}
var _burn_damage_per_tick: int = 0
var _burn_ticks_remaining: int = 0
var _burn_elapsed: float = 0.0
var _chill_remaining: float = 0.0
var _chill_bonus_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("blocks")
	collision_layer = 2
	collision_mask = 0
	if current_hp <= 0:
		current_hp = maxi(1, max_hp)
	_ensure_nodes()
	_update_visual()


func _process(delta: float) -> void:
	_process_statuses(delta)

	if _flash_remaining > 0.0:
		_flash_remaining = maxf(0.0, _flash_remaining - delta)
		var flash_weight: float = 1.0 - (_flash_remaining / FLASH_DURATION)
		if _visual != null:
			_visual.color = _active_flash_color.lerp(_base_color, flash_weight)

	if _punch_remaining > 0.0:
		_punch_remaining = maxf(0.0, _punch_remaining - delta)
		var punch_weight: float = _punch_remaining / PUNCH_DURATION
		scale = Vector2.ONE * (1.0 + (0.08 * punch_weight))
	else:
		scale = Vector2.ONE


func setup_from_definition(definition: Dictionary) -> void:
	block_id = StringName(String(definition.get("id", "basic_block")))
	display_name = String(definition.get("display_name", "Basic Block"))
	max_hp = maxi(1, int(definition.get("base_hp", definition.get("hp", 1))))
	current_hp = max_hp
	behaviour_type = StringName(String(definition.get("behaviour_type", "basic")))

	var color_value: Variant = definition.get("color", "#2f97c7")
	block_color = Color.from_string(String(color_value), Color(0.18, 0.57, 0.78, 1.0))
	_base_color = block_color

	var parameters_value: Variant = definition.get("parameters", {})
	parameters = {}
	if parameters_value is Dictionary:
		parameters = (parameters_value as Dictionary).duplicate(true)
	_armour_source_ids.clear()
	_clear_statuses()

	if is_inside_tree():
		_ensure_nodes()
		_update_visual()


func configure(hp: int, new_block_size: Vector2) -> void:
	max_hp = maxi(1, hp)
	current_hp = max_hp
	block_size = new_block_size

	if is_inside_tree():
		_ensure_nodes()
		_update_visual()


func take_damage(amount: int, hit_position: Vector2, source_ball: Node = null) -> int:
	if _is_destroyed or current_hp <= 0:
		return 0

	var incoming_damage: int = _apply_chill_bonus(maxi(0, amount))
	if incoming_damage <= 0:
		return 0

	var damage_taken: int = _calculate_damage_after_armour(incoming_damage, hit_position, source_ball)
	current_hp = maxi(0, current_hp - damage_taken)
	_play_hit_feedback(Color(1.0, 0.95, 0.62, 1.0))
	_update_visual()
	hit.emit(self, damage_taken, hit_position, source_ball)

	if current_hp > 0:
		_apply_on_hit_effects(hit_position, source_ball)
	else:
		_apply_on_destroy_effects(hit_position, source_ball)
		_destroy_block(hit_position, source_ball)

	return damage_taken


func apply_hit(damage: int = 1) -> void:
	take_damage(damage, global_position, null)


func heal(amount: int) -> int:
	if _is_destroyed or current_hp <= 0:
		return 0

	var previous_hp: int = current_hp
	current_hp = mini(max_hp, current_hp + maxi(0, amount))
	var healed_amount: int = current_hp - previous_hp
	if healed_amount > 0:
		_play_hit_feedback(Color(0.62, 1.0, 0.55, 1.0))
		_update_visual()
	return healed_amount


func apply_burn(damage_per_tick: int, ticks: int) -> void:
	if _is_destroyed or current_hp <= 0:
		return

	_burn_damage_per_tick = maxi(_burn_damage_per_tick, damage_per_tick)
	_burn_ticks_remaining = maxi(_burn_ticks_remaining, ticks)
	_burn_elapsed = 0.0
	_play_hit_feedback(Color(1.0, 0.46, 0.22, 1.0))


func apply_chill(duration: float, bonus_multiplier: float) -> void:
	if _is_destroyed or current_hp <= 0:
		return

	_chill_remaining = maxf(_chill_remaining, duration)
	_chill_bonus_multiplier = maxf(_chill_bonus_multiplier, bonus_multiplier)
	_play_hit_feedback(Color(0.55, 0.9, 1.0, 1.0))


func receive_chain_damage(amount: int) -> int:
	return _apply_status_damage(amount, Color(1.0, 0.95, 0.35, 1.0))


func is_alive() -> bool:
	return not _is_destroyed and current_hp > 0


func get_float_parameter(parameter_name: String, default_value: float) -> float:
	return float(parameters.get(parameter_name, default_value))


func get_int_parameter(parameter_name: String, default_value: int) -> int:
	return int(parameters.get(parameter_name, default_value))


func _process_statuses(delta: float) -> void:
	if _chill_remaining > 0.0:
		_chill_remaining = maxf(0.0, _chill_remaining - delta)
		if _chill_remaining <= 0.0:
			_chill_bonus_multiplier = 1.0

	if _burn_ticks_remaining <= 0:
		return

	_burn_elapsed += delta
	while _burn_elapsed >= BURN_TICK_INTERVAL and _burn_ticks_remaining > 0:
		_burn_elapsed -= BURN_TICK_INTERVAL
		_burn_ticks_remaining -= 1
		_apply_status_damage(_burn_damage_per_tick, Color(1.0, 0.42, 0.2, 1.0))


func _apply_chill_bonus(amount: int) -> int:
	if _chill_remaining <= 0.0 or _chill_bonus_multiplier <= 1.0:
		return amount

	var boosted_damage: int = maxi(1, ceili(float(amount) * _chill_bonus_multiplier))
	_chill_remaining = 0.0
	_chill_bonus_multiplier = 1.0
	return boosted_damage


func _apply_status_damage(amount: int, flash_color: Color) -> int:
	if _is_destroyed or current_hp <= 0:
		return 0

	var damage_taken: int = maxi(0, amount)
	if damage_taken <= 0:
		return 0

	current_hp = maxi(0, current_hp - damage_taken)
	_play_hit_feedback(flash_color)
	_update_visual()
	hit.emit(self, damage_taken, global_position, null)

	if current_hp <= 0:
		_apply_on_destroy_effects(global_position, null)
		_destroy_block(global_position, null)

	return damage_taken


func _clear_statuses() -> void:
	_burn_damage_per_tick = 0
	_burn_ticks_remaining = 0
	_burn_elapsed = 0.0
	_chill_remaining = 0.0
	_chill_bonus_multiplier = 1.0


func _calculate_damage_after_armour(incoming_damage: int, hit_position: Vector2, source_ball: Node) -> int:
	if String(behaviour_type) != "frost":
		return incoming_damage

	var armour: int = get_int_parameter("armour", get_int_parameter("armor", 0))
	if armour <= 0:
		return incoming_damage

	if source_ball != null:
		var source_id: int = source_ball.get_instance_id()
		if _armour_source_ids.has(source_id):
			return incoming_damage
		_armour_source_ids[source_id] = true

	var reduced_damage: int = maxi(0, incoming_damage - armour)
	special_effect_requested.emit(self, StringName("armor"), hit_position, {"armour": armour}, source_ball)
	return reduced_damage


func _apply_on_hit_effects(hit_position: Vector2, source_ball: Node) -> void:
	match String(behaviour_type):
		"bloom":
			special_effect_requested.emit(self, StringName("heal"), global_position, parameters.duplicate(true), source_ball)
		"mirror":
			_apply_mirror_boost(source_ball)
			special_effect_requested.emit(self, StringName("boost"), hit_position, parameters.duplicate(true), source_ball)
		"void":
			special_effect_requested.emit(self, StringName("pull"), hit_position, parameters.duplicate(true), source_ball)


func _apply_on_destroy_effects(_hit_position: Vector2, source_ball: Node) -> void:
	if String(behaviour_type) == "ember":
		special_effect_requested.emit(self, StringName("explode"), global_position, parameters.duplicate(true), source_ball)


func _apply_mirror_boost(source_ball: Node) -> void:
	if source_ball == null or not source_ball.has_method("apply_speed_boost"):
		return

	var speed_multiplier: float = get_float_parameter("speed_multiplier", 1.12)
	var max_speed: float = get_float_parameter("max_speed", 1120.0)
	source_ball.call("apply_speed_boost", speed_multiplier, max_speed)


func _play_hit_feedback(flash_color: Color) -> void:
	_active_flash_color = flash_color
	_flash_remaining = FLASH_DURATION
	_punch_remaining = PUNCH_DURATION


func _destroy_block(hit_position: Vector2, source_ball: Node) -> void:
	_is_destroyed = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	destroyed.emit(self, hit_position, source_ball)
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
		_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_border.default_color = _border_color_for_behaviour()

	_hp_label.position = -half_size
	_hp_label.size = block_size
	_hp_label.text = str(current_hp)
	_hp_label.tooltip_text = display_name

	var rectangle_shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		rectangle_shape.size = block_size


func _border_color_for_behaviour() -> Color:
	match String(behaviour_type):
		"bloom":
			return Color(0.72, 1.0, 0.65, 1.0)
		"ember":
			return Color(1.0, 0.78, 0.42, 1.0)
		"frost":
			return Color(0.72, 0.98, 1.0, 1.0)
		"mirror":
			return Color(0.7, 1.0, 0.96, 1.0)
		"void":
			return Color(0.82, 0.64, 1.0, 1.0)
		"stone":
			return Color(0.9, 0.92, 0.95, 0.85)
		_:
			return Color(0.9, 0.95, 1.0, 0.9)
