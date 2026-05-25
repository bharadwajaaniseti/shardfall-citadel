class_name GameplayController
extends Node2D

const BLOCK_SIZE: Vector2 = Vector2(112.0, 46.0)
const BLOCK_GAP: Vector2 = Vector2(14.0, 12.0)
const BASE_COLUMNS: int = 7
const BASE_ROWS: int = 3
const MAX_COLUMNS: int = 10
const MAX_ROWS: int = 5
const FIRST_BLOCK_Y: float = 190.0
const CANNON_RETURN_OFFSET: float = 86.0
const MIN_LAUNCH_Y: float = -0.05
const NEXT_WAVE_DELAY: float = 0.6
const BALL_IDS: Array[StringName] = [
	StringName("basic_orb"),
	StringName("heavy_orb"),
	StringName("ember_orb"),
	StringName("frost_orb"),
	StringName("spark_orb"),
	StringName("split_orb"),
	StringName("drill_orb"),
]
const BALL_LAUNCH_DELAY: float = 0.08
const BALL_SPREAD_DEGREES: float = 5.0

@onready var cannon: Cannon = %Cannon
@onready var aim_guide: AimGuide = %AimGuide
@onready var balls_container: Node2D = %Balls
@onready var blocks_container: Node2D = %Blocks
@onready var effects_container: Node2D = %Effects
@onready var wave_value_label: Label = %WaveValueLabel
@onready var blocks_value_label: Label = %BlocksValueLabel
@onready var shots_value_label: Label = %ShotsValueLabel
@onready var selected_ball_value_label: Label = %SelectedBallValueLabel
@onready var balls_value_label: Label = %BallsValueLabel
@onready var citadel_value_label: Label = %CitadelValueLabel
@onready var status_value_label: Label = %StatusValueLabel

@export var debug_shooting: bool = false

var current_wave: int = 1
var blocks_remaining: int = 0
var active_balls: int = 0
var launched_count: int = 0
var balls_launched_this_shot: int = 0
var balls_returned_this_shot: int = 0
var citadel_hp: int = 100
var max_citadel_hp: int = 100
var can_fire: bool = true
var wave_spawn_pending: bool = false
var pending_next_wave: int = 0
var next_wave_timer_started: bool = false
var selected_ball_id: StringName = StringName("basic_orb")
var selected_ball_display_name: String = "Basic Orb"
var balls_per_shot: int = 1


func _ready() -> void:
	randomize()
	_refresh_selected_ball_name()
	print("Phase 3 test controls: 1-7 select orb, +/- balls per shot, B cycles, left click fires.")
	_spawn_wave(current_wave)
	_refresh_hud()


func _process(_delta: float) -> void:
	var aim_direction: Vector2 = _get_launch_direction(get_global_mouse_position())
	cannon.set_aim_direction(aim_direction)

	var guide_is_visible: bool = can_fire and active_balls == 0 and blocks_remaining > 0
	var muzzle_position: Vector2 = aim_guide.to_local(cannon.get_muzzle_global_position())
	aim_guide.update_guide(muzzle_position, aim_direction, guide_is_visible)


func _physics_process(delta: float) -> void:
	_apply_void_attraction(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var click_position: Vector2 = get_global_mouse_position()
			if debug_shooting:
				print("Gameplay click detected")
			_try_fire(click_position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		_handle_debug_key(key_event)


func _handle_debug_key(key_event: InputEventKey) -> void:
	match key_event.keycode:
		KEY_1:
			_select_ball_by_index(0)
		KEY_2:
			_select_ball_by_index(1)
		KEY_3:
			_select_ball_by_index(2)
		KEY_4:
			_select_ball_by_index(3)
		KEY_5:
			_select_ball_by_index(4)
		KEY_6:
			_select_ball_by_index(5)
		KEY_7:
			_select_ball_by_index(6)
		KEY_B:
			_cycle_ball_type()
		KEY_EQUAL, KEY_KP_ADD:
			_adjust_balls_per_shot(1)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_adjust_balls_per_shot(-1)
		_:
			return

	get_viewport().set_input_as_handled()


func _try_fire(mouse_global_position: Vector2) -> void:
	if not can_fire or active_balls > 0 or blocks_remaining <= 0:
		if debug_shooting:
			print("Shot blocked. can_fire=%s active_balls=%s blocks_remaining=%s" % [can_fire, active_balls, blocks_remaining])
		return

	var muzzle_position: Vector2 = cannon.get_muzzle_global_position()
	var base_launch_direction: Vector2 = _get_launch_direction(mouse_global_position)
	var ball_definition: Dictionary = _get_selected_ball_definition()
	var launch_total: int = maxi(1, balls_per_shot)

	if debug_shooting:
		print("Cannon position: %s" % cannon.global_position)
		print("Muzzle position: %s" % muzzle_position)
		print("Mouse position: %s" % mouse_global_position)
		print("Launch direction: %s" % base_launch_direction)
		print("Selected ball: %s" % selected_ball_display_name)
		print("Balls per shot: %s" % launch_total)

	can_fire = false
	active_balls += launch_total
	balls_launched_this_shot = launch_total
	balls_returned_this_shot = 0
	_set_status("Launching %s" % selected_ball_display_name)

	var center_offset: float = (float(launch_total) - 1.0) * 0.5
	for index in range(launch_total):
		var angle_offset: float = deg_to_rad((float(index) - center_offset) * BALL_SPREAD_DEGREES)
		var launch_direction: Vector2 = base_launch_direction.rotated(angle_offset).normalized()
		if launch_direction.y > MIN_LAUNCH_Y:
			launch_direction.y = MIN_LAUNCH_Y
			launch_direction = launch_direction.normalized()
		var delay: float = float(index) * BALL_LAUNCH_DELAY
		_schedule_ball_launch(launch_direction, ball_definition, muzzle_position, delay)

	_refresh_hud()


func _schedule_ball_launch(direction: Vector2, definition: Dictionary, spawn_position: Vector2, delay: float) -> void:
	if delay <= 0.0:
		_spawn_ball(direction, definition, spawn_position)
		return

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	timer.timeout.connect(_on_ball_launch_timer_timeout.bind(timer, direction, definition.duplicate(true), spawn_position))
	add_child(timer)
	timer.start()


func _on_ball_launch_timer_timeout(timer: Timer, direction: Vector2, definition: Dictionary, spawn_position: Vector2) -> void:
	timer.queue_free()
	_spawn_ball(direction, definition, spawn_position)


func _spawn_ball(direction: Vector2, definition: Dictionary, spawn_position: Vector2, damage_multiplier: float = 1.0, split_child: bool = false) -> Ball:
	var ball: Ball = Ball.new()
	ball.controller = self
	ball.setup_from_definition(definition)
	if split_child:
		ball.mark_as_split_child(damage_multiplier)
	ball.configure(cannon.global_position.y + CANNON_RETURN_OFFSET, 0)
	ball.returned.connect(_on_ball_returned)
	ball.block_hit.connect(_on_ball_hit_block)
	ball.impact.connect(_on_ball_impact)
	ball.chain_requested.connect(_on_ball_chain_requested)
	ball.split_requested.connect(_on_ball_split_requested)
	ball.feedback_requested.connect(_on_ball_feedback_requested)
	balls_container.add_child(ball)
	ball.global_position = spawn_position
	ball.launch(direction)
	launched_count += 1

	if debug_shooting:
		print("Ball instance created: %s at %s" % [ball, ball.global_position])

	_refresh_hud()
	return ball


func _get_launch_direction(mouse_global_position: Vector2) -> Vector2:
	var raw_direction: Vector2 = mouse_global_position - cannon.global_position
	if raw_direction.length_squared() <= 0.001:
		raw_direction = Vector2.UP

	if raw_direction.y > MIN_LAUNCH_Y:
		raw_direction.y = MIN_LAUNCH_Y

	return raw_direction.normalized()


func _spawn_wave(wave_number: int) -> void:
	_clear_blocks()
	current_wave = maxi(1, wave_number)

	var wave_index: int = current_wave - 1
	var columns: int = mini(MAX_COLUMNS, BASE_COLUMNS + floori(float(wave_index) / 2.0))
	var rows: int = mini(MAX_ROWS, BASE_ROWS + floori(float(wave_index) / 3.0))
	var total_width: float = (float(columns) * BLOCK_SIZE.x) + (float(columns - 1) * BLOCK_GAP.x)
	var start_x: float = 960.0 - (total_width * 0.5) + (BLOCK_SIZE.x * 0.5)

	wave_spawn_pending = false
	pending_next_wave = 0
	next_wave_timer_started = false
	blocks_remaining = 0
	balls_launched_this_shot = 0
	balls_returned_this_shot = 0
	for row in range(rows):
		for column in range(columns):
			if not _should_spawn_cell(row, column, rows, columns):
				continue

			var block_id: StringName = _select_block_id(row, column, rows, columns, current_wave)
			var block_definition: Dictionary = _get_scaled_block_definition(block_id, row)
			var block: BreakableBlock = BreakableBlock.new()
			block.block_size = BLOCK_SIZE
			block.setup_from_definition(block_definition)
			block.position = Vector2(
				start_x + (float(column) * (BLOCK_SIZE.x + BLOCK_GAP.x)),
				FIRST_BLOCK_Y + (float(row) * (BLOCK_SIZE.y + BLOCK_GAP.y))
			)
			block.hit.connect(_on_block_hit)
			block.destroyed.connect(_on_block_destroyed)
			block.special_effect_requested.connect(_on_block_special_effect_requested)
			blocks_container.add_child(block)
			blocks_remaining += 1

	can_fire = active_balls == 0
	if can_fire:
		_set_status("Ready to fire")
	else:
		_set_status("Ball in play")
	_spawn_wave_popup("Wave %s" % current_wave)
	_refresh_hud()


func _clear_blocks() -> void:
	var children: Array = blocks_container.get_children()
	for child in children:
		var node: Node = child as Node
		if node != null:
			node.queue_free()


func _on_ball_returned(_ball: Ball) -> void:
	active_balls = maxi(0, active_balls - 1)
	balls_returned_this_shot = mini(balls_launched_this_shot, balls_returned_this_shot + 1)

	if active_balls == 0:
		if wave_spawn_pending:
			_set_status("Preparing next wave")
			_maybe_start_next_wave_delay()
		elif blocks_remaining > 0:
			can_fire = true
			_set_status("Ready to fire")

	_refresh_hud()


func _on_ball_hit_block(_block: BreakableBlock, _damage: int) -> void:
	_refresh_hud()


func _on_ball_chain_requested(_ball: Ball, source_block: BreakableBlock, chain_range: float, chain_damage: int) -> void:
	if source_block == null or chain_damage <= 0:
		return

	var target_block: BreakableBlock = _find_nearest_block(source_block.global_position, source_block, chain_range)
	if target_block == null:
		return

	var damage_taken: int = target_block.receive_chain_damage(chain_damage)
	if damage_taken <= 0:
		return

	_spawn_special_text("CHAIN", target_block.global_position + Vector2(0.0, -58.0), Color(1.0, 0.96, 0.32, 1.0), 22)
	_spawn_impact_flash(target_block.global_position)
	_refresh_hud()


func _on_ball_split_requested(ball: Ball, split_count: int, damage_multiplier: float) -> void:
	if ball == null or split_count <= 0:
		return

	var definition: Dictionary = ball.get_definition_snapshot()
	if definition.is_empty():
		definition = _get_ball_definition(selected_ball_id)

	var parent_direction: Vector2 = ball.velocity.normalized()
	if parent_direction.length_squared() <= 0.001:
		parent_direction = Vector2.UP

	var center_offset: float = (float(split_count) - 1.0) * 0.5
	for index in range(split_count):
		var angle_offset: float = deg_to_rad((float(index) - center_offset) * 18.0)
		var child_direction: Vector2 = parent_direction.rotated(angle_offset).normalized()
		var child_position: Vector2 = ball.global_position + child_direction * (ball.radius + 18.0)
		active_balls += 1
		balls_launched_this_shot += 1
		var child_ball: Ball = _spawn_ball(child_direction, definition, child_position, damage_multiplier, true)
		child_ball.disable_block_collision_briefly(0.12)

	_refresh_hud()


func _on_ball_feedback_requested(text: String, world_position: Vector2, color: Color) -> void:
	_spawn_special_text(text, world_position, color, 22)


func _on_block_hit(block: BreakableBlock, damage_taken: int, _hit_position: Vector2, _source_ball: Node) -> void:
	if damage_taken > 0:
		_spawn_damage_number(block.global_position + Vector2(0.0, -38.0), damage_taken)
	_refresh_hud()


func _on_ball_impact(world_position: Vector2) -> void:
	_spawn_impact_flash(world_position)


func _on_block_destroyed(block: BreakableBlock, _hit_position: Vector2, _source_ball: Node) -> void:
	blocks_remaining = maxi(0, blocks_remaining - 1)
	_emit_block_destroyed(block)
	_spawn_burst(block.global_position, block.block_color)

	if blocks_remaining == 0 and not wave_spawn_pending:
		wave_spawn_pending = true
		pending_next_wave = current_wave + 1
		can_fire = false
		if active_balls > 0:
			_set_status("Wave cleared - returning balls")
		else:
			_set_status("Wave cleared")
		_maybe_start_next_wave_delay()

	_refresh_hud()


func _on_block_special_effect_requested(block: BreakableBlock, effect_id: StringName, world_position: Vector2, parameters: Dictionary, _source_ball: Node) -> void:
	match String(effect_id):
		"heal":
			var heal_radius: float = float(parameters.get("heal_radius", 120.0))
			var heal_amount: int = int(parameters.get("heal_amount", 1))
			_spawn_special_text("HEAL", world_position + Vector2(0.0, -56.0), Color(0.62, 1.0, 0.55, 1.0))
			_heal_blocks_near(block, world_position, heal_radius, heal_amount)
		"explode":
			var explosion_radius: float = float(parameters.get("explosion_radius", 130.0))
			var explosion_damage: int = int(parameters.get("explosion_damage", 1))
			_spawn_special_text("BOOM", world_position + Vector2(0.0, -56.0), Color(1.0, 0.68, 0.32, 1.0), 28)
			_spawn_burst(world_position, Color(1.0, 0.45, 0.2, 1.0))
			_damage_blocks_near(block, world_position, explosion_radius, explosion_damage)
		"armor":
			_spawn_special_text("ARMOR", world_position + Vector2(0.0, -48.0), Color(0.72, 0.95, 1.0, 1.0), 22)
		"boost":
			_spawn_special_text("BOOST", world_position + Vector2(0.0, -48.0), Color(0.62, 1.0, 0.95, 1.0), 22)
		"pull":
			_spawn_special_text("PULL", world_position + Vector2(0.0, -48.0), Color(0.82, 0.64, 1.0, 1.0), 22)


func _emit_block_destroyed(block: BreakableBlock) -> void:
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus == null or not event_bus.has_signal("block_destroyed"):
		return

	event_bus.emit_signal("block_destroyed", StringName("prototype_block"), block.global_position, {})


func _refresh_hud() -> void:
	wave_value_label.text = str(current_wave)
	blocks_value_label.text = str(blocks_remaining)
	shots_value_label.text = "Launched %s" % launched_count
	selected_ball_value_label.text = "%s x%s" % [selected_ball_display_name, balls_per_shot]
	balls_value_label.text = "%s active / %s returned" % [active_balls, balls_returned_this_shot]
	citadel_value_label.text = "%s/%s" % [citadel_hp, max_citadel_hp]


func _set_status(message: String) -> void:
	status_value_label.text = message


func _maybe_start_next_wave_delay() -> void:
	if not wave_spawn_pending or next_wave_timer_started or active_balls > 0 or pending_next_wave <= 0:
		return

	_start_next_wave_after_delay(pending_next_wave)


func _start_next_wave_after_delay(next_wave: int) -> void:
	next_wave_timer_started = true
	_set_status("Next wave incoming")
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = NEXT_WAVE_DELAY
	timer.timeout.connect(_on_next_wave_timer_timeout.bind(timer, next_wave))
	add_child(timer)
	timer.start()


func _on_next_wave_timer_timeout(timer: Timer, next_wave: int) -> void:
	timer.queue_free()
	next_wave_timer_started = false
	_spawn_wave(next_wave)


func _spawn_impact_flash(world_position: Vector2) -> void:
	var flash: ImpactFlash = ImpactFlash.new()
	flash.global_position = world_position
	effects_container.add_child(flash)


func _spawn_damage_number(world_position: Vector2, damage: int) -> void:
	if damage <= 0:
		return

	var floating_text: FloatingText = FloatingText.new()
	floating_text.global_position = world_position
	floating_text.configure("-%s" % damage, Color(1.0, 0.92, 0.42, 1.0), 24, 0.55, Vector2(0.0, -42.0))
	effects_container.add_child(floating_text)


func _spawn_burst(world_position: Vector2, burst_color: Color = Color(1.0, 0.82, 0.35, 1.0)) -> void:
	var burst: BurstEffect = BurstEffect.new()
	burst.global_position = world_position
	burst.burst_color = burst_color
	effects_container.add_child(burst)


func _spawn_wave_popup(text: String) -> void:
	var popup: FloatingText = FloatingText.new()
	popup.global_position = Vector2(960.0, 124.0)
	popup.configure(text, Color(0.72, 0.96, 1.0, 1.0), 38, 0.9, Vector2(0.0, -28.0))
	effects_container.add_child(popup)


func _spawn_special_text(text: String, world_position: Vector2, text_color: Color, font_size: int = 22) -> void:
	var floating_text: FloatingText = FloatingText.new()
	floating_text.global_position = world_position
	floating_text.configure(text, text_color, font_size, 0.62, Vector2(0.0, -36.0))
	effects_container.add_child(floating_text)


func _heal_blocks_near(source_block: BreakableBlock, center: Vector2, radius: float, amount: int) -> void:
	var children: Array = blocks_container.get_children()
	for child in children:
		var target_block: BreakableBlock = child as BreakableBlock
		if target_block == null or target_block == source_block or not target_block.is_alive():
			continue

		if target_block.global_position.distance_to(center) > radius:
			continue

		var healed_amount: int = target_block.heal(amount)
		if healed_amount > 0:
			_spawn_special_text("HEAL", target_block.global_position + Vector2(0.0, -46.0), Color(0.62, 1.0, 0.55, 1.0), 18)


func _damage_blocks_near(source_block: BreakableBlock, center: Vector2, radius: float, amount: int) -> void:
	var children: Array = blocks_container.get_children()
	for child in children:
		var target_block: BreakableBlock = child as BreakableBlock
		if target_block == null or target_block == source_block or not target_block.is_alive():
			continue

		if target_block.global_position.distance_to(center) > radius:
			continue

		var damage_taken: int = target_block.take_damage(amount, target_block.global_position, null)
		if damage_taken > 0:
			_spawn_impact_flash(target_block.global_position)


func _find_nearest_block(center: Vector2, excluded_block: BreakableBlock, radius: float) -> BreakableBlock:
	var nearest_block: BreakableBlock = null
	var nearest_distance_squared: float = radius * radius
	var children: Array = blocks_container.get_children()
	for child in children:
		var target_block: BreakableBlock = child as BreakableBlock
		if target_block == null or target_block == excluded_block or not target_block.is_alive():
			continue

		var distance_squared: float = target_block.global_position.distance_squared_to(center)
		if distance_squared > nearest_distance_squared:
			continue

		nearest_distance_squared = distance_squared
		nearest_block = target_block

	return nearest_block


func _apply_void_attraction(delta: float) -> void:
	var ball_children: Array = balls_container.get_children()
	var block_children: Array = blocks_container.get_children()

	for ball_child in ball_children:
		var ball: Ball = ball_child as Ball
		if ball == null or not ball.is_active:
			continue

		for block_child in block_children:
			var block: BreakableBlock = block_child as BreakableBlock
			if block == null or not block.is_alive() or String(block.behaviour_type) != "void":
				continue

			var attraction_radius: float = block.get_float_parameter("attraction_radius", 190.0)
			var attraction_strength: float = block.get_float_parameter("attraction_strength", 210.0)
			var distance: float = ball.global_position.distance_to(block.global_position)
			if distance <= 0.001 or distance > attraction_radius:
				continue

			var falloff: float = 1.0 - clampf(distance / attraction_radius, 0.0, 1.0)
			ball.apply_attraction(block.global_position, attraction_strength * falloff, delta)


func _get_scaled_block_definition(block_id: StringName, row: int) -> Dictionary:
	var definition: Dictionary = _get_block_definition(block_id)
	var scaled_definition: Dictionary = definition.duplicate(true)
	var base_hp: int = int(scaled_definition.get("base_hp", scaled_definition.get("hp", 1)))
	var wave_hp_bonus: int = floori(float(maxi(0, current_wave - 1)) / 2.0)
	var row_hp_bonus: int = 1 if row == 0 and current_wave > 1 else 0
	scaled_definition["base_hp"] = maxi(1, base_hp + wave_hp_bonus + row_hp_bonus)
	return scaled_definition


func _get_block_definition(block_id: StringName) -> Dictionary:
	var database: Node = get_node_or_null("/root/GameDatabase")
	if database != null and database.has_method("get_block"):
		var definition: Dictionary = database.call("get_block", block_id) as Dictionary
		if not definition.is_empty():
			return definition

	return {
		"id": String(block_id),
		"display_name": "Basic Block",
		"base_hp": 1,
		"color": "#2f97c7",
		"description": "Fallback block definition.",
		"behaviour_type": "basic",
		"parameters": {},
	}


func _get_selected_ball_definition() -> Dictionary:
	return _get_ball_definition(selected_ball_id)


func _get_ball_definition(ball_id: StringName) -> Dictionary:
	var database: Node = get_node_or_null("/root/GameDatabase")
	if database != null and database.has_method("get_ball"):
		var definition: Dictionary = database.call("get_ball", String(ball_id)) as Dictionary
		if not definition.is_empty():
			return definition

	return {
		"id": "basic_orb",
		"display_name": "Basic Orb",
		"description": "Fallback starter orb.",
		"base_damage": 1,
		"speed": 840.0,
		"radius": 12.0,
		"color": "#dfffe8",
		"behaviour_type": "basic",
		"parameters": {},
	}


func _select_ball_by_index(index: int) -> void:
	if index < 0 or index >= BALL_IDS.size():
		return

	selected_ball_id = BALL_IDS[index]
	_refresh_selected_ball_name()
	_set_status("Selected %s" % selected_ball_display_name)
	_refresh_hud()


func _cycle_ball_type() -> void:
	var current_index: int = BALL_IDS.find(selected_ball_id)
	if current_index < 0:
		current_index = 0
	else:
		current_index = (current_index + 1) % BALL_IDS.size()
	_select_ball_by_index(current_index)


func _adjust_balls_per_shot(amount: int) -> void:
	balls_per_shot = clampi(balls_per_shot + amount, 1, 12)
	_set_status("Balls per shot: %s" % balls_per_shot)
	_refresh_hud()


func _refresh_selected_ball_name() -> void:
	var definition: Dictionary = _get_ball_definition(selected_ball_id)
	selected_ball_display_name = String(definition.get("display_name", "Basic Orb"))


func _select_block_id(row: int, column: int, rows: int, columns: int, wave: int) -> StringName:
	# Test order: wave 1 basic/stone, wave 2 bloom/ember, wave 3 frost, wave 4 mirror, wave 5 void.
	if wave >= 5 and row == 1 and column == columns - 2:
		return StringName("void_stone")
	if wave >= 5 and (row + column + wave) % 13 == 0:
		return StringName("void_stone")
	if wave >= 4 and row == rows - 1 and column == 1:
		return StringName("mirror_shard")
	if wave >= 4 and (row * 2 + column + wave) % 9 == 0:
		return StringName("mirror_shard")
	if wave >= 3 and row == 0 and column % 4 == 1:
		return StringName("frost_shell")
	if wave >= 2 and row == 1 and column % 5 == 0:
		return StringName("bloom_pod")
	if wave >= 2 and row == 0 and column % 5 == 3:
		return StringName("ember_crystal")
	if row == 0 or (row + column + wave) % 4 == 0:
		return StringName("stone_block")
	return StringName("basic_block")


func _should_spawn_cell(row: int, column: int, rows: int, columns: int) -> bool:
	if row == 0:
		return true
	if current_wave < 2:
		return true
	if row == rows - 1 and (column + current_wave) % 5 == 0:
		return false
	if current_wave >= 4 and row == 1 and column > 0 and column < columns - 1 and column % 7 == 0:
		return false
	return true
