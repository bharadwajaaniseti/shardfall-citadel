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

@onready var cannon: Cannon = %Cannon
@onready var aim_guide: AimGuide = %AimGuide
@onready var balls_container: Node2D = %Balls
@onready var blocks_container: Node2D = %Blocks
@onready var effects_container: Node2D = %Effects
@onready var wave_value_label: Label = %WaveValueLabel
@onready var blocks_value_label: Label = %BlocksValueLabel
@onready var shots_value_label: Label = %ShotsValueLabel
@onready var citadel_value_label: Label = %CitadelValueLabel
@onready var status_value_label: Label = %StatusValueLabel

@export var debug_shooting: bool = false

var current_wave: int = 1
var blocks_remaining: int = 0
var active_balls: int = 0
var launched_count: int = 0
var citadel_hp: int = 100
var max_citadel_hp: int = 100
var can_fire: bool = true
var wave_spawn_pending: bool = false


func _ready() -> void:
	_spawn_wave(current_wave)
	_refresh_hud()


func _process(_delta: float) -> void:
	var aim_direction: Vector2 = _get_launch_direction(get_global_mouse_position())
	cannon.set_aim_direction(aim_direction)

	var guide_is_visible: bool = can_fire and active_balls == 0 and blocks_remaining > 0
	var muzzle_position: Vector2 = aim_guide.to_local(cannon.get_muzzle_global_position())
	aim_guide.update_guide(muzzle_position, aim_direction, guide_is_visible)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var click_position: Vector2 = get_global_mouse_position()
			if debug_shooting:
				print("Gameplay click detected")
			_try_fire(click_position)
			get_viewport().set_input_as_handled()


func _try_fire(mouse_global_position: Vector2) -> void:
	if not can_fire or active_balls > 0 or blocks_remaining <= 0:
		if debug_shooting:
			print("Shot blocked. can_fire=%s active_balls=%s blocks_remaining=%s" % [can_fire, active_balls, blocks_remaining])
		return

	var muzzle_position: Vector2 = cannon.get_muzzle_global_position()
	var launch_direction: Vector2 = _get_launch_direction(mouse_global_position)

	if debug_shooting:
		print("Cannon position: %s" % cannon.global_position)
		print("Mouse position: %s" % mouse_global_position)
		print("Launch direction: %s" % launch_direction)

	var ball: Ball = Ball.new()
	balls_container.add_child(ball)
	ball.global_position = muzzle_position
	ball.configure(cannon.global_position.y + CANNON_RETURN_OFFSET, 1)
	ball.returned.connect(_on_ball_returned)
	ball.block_hit.connect(_on_ball_hit_block)
	ball.impact.connect(_on_ball_impact)
	ball.launch(launch_direction)

	if debug_shooting:
		print("Ball instance created: %s at %s" % [ball, ball.global_position])

	active_balls += 1
	launched_count += 1
	can_fire = false
	_set_status("Ball in play")
	_refresh_hud()


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
	var base_hp: int = 1 + floori(float(wave_index) / 2.0)
	var total_width: float = (float(columns) * BLOCK_SIZE.x) + (float(columns - 1) * BLOCK_GAP.x)
	var start_x: float = 960.0 - (total_width * 0.5) + (BLOCK_SIZE.x * 0.5)

	wave_spawn_pending = false
	blocks_remaining = 0
	for row in range(rows):
		for column in range(columns):
			var block: BreakableBlock = BreakableBlock.new()
			var row_hp_bonus: int = 1 if row == 0 and current_wave > 1 else 0
			var block_hp: int = base_hp + row_hp_bonus
			block.configure(block_hp, BLOCK_SIZE)
			block.position = Vector2(
				start_x + (float(column) * (BLOCK_SIZE.x + BLOCK_GAP.x)),
				FIRST_BLOCK_Y + (float(row) * (BLOCK_SIZE.y + BLOCK_GAP.y))
			)
			block.destroyed.connect(_on_block_destroyed)
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
	if active_balls == 0 and blocks_remaining > 0:
		can_fire = true
		_set_status("Ready to fire")
	_refresh_hud()


func _on_ball_hit_block(block: BreakableBlock, damage: int) -> void:
	_spawn_damage_number(block.global_position + Vector2(0.0, -38.0), damage)
	_refresh_hud()


func _on_ball_impact(world_position: Vector2) -> void:
	_spawn_impact_flash(world_position)


func _on_block_destroyed(block: BreakableBlock) -> void:
	blocks_remaining = maxi(0, blocks_remaining - 1)
	_emit_block_destroyed(block)

	if blocks_remaining == 0 and not wave_spawn_pending:
		wave_spawn_pending = true
		can_fire = false
		_set_status("Wave cleared")
		_spawn_burst(block.global_position)
		_start_next_wave_after_delay(current_wave + 1)
	else:
		_spawn_burst(block.global_position)

	_refresh_hud()


func _emit_block_destroyed(block: BreakableBlock) -> void:
	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus == null or not event_bus.has_signal("block_destroyed"):
		return

	event_bus.emit_signal("block_destroyed", StringName("prototype_block"), block.global_position, {})


func _refresh_hud() -> void:
	wave_value_label.text = str(current_wave)
	blocks_value_label.text = str(blocks_remaining)
	shots_value_label.text = "Launched %s" % launched_count
	citadel_value_label.text = "%s/%s" % [citadel_hp, max_citadel_hp]


func _set_status(message: String) -> void:
	status_value_label.text = message


func _start_next_wave_after_delay(next_wave: int) -> void:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = NEXT_WAVE_DELAY
	timer.timeout.connect(_on_next_wave_timer_timeout.bind(timer, next_wave))
	add_child(timer)
	timer.start()


func _on_next_wave_timer_timeout(timer: Timer, next_wave: int) -> void:
	timer.queue_free()
	_spawn_wave(next_wave)


func _spawn_impact_flash(world_position: Vector2) -> void:
	var flash: ImpactFlash = ImpactFlash.new()
	flash.global_position = world_position
	effects_container.add_child(flash)


func _spawn_damage_number(world_position: Vector2, damage: int) -> void:
	var floating_text: FloatingText = FloatingText.new()
	floating_text.global_position = world_position
	floating_text.configure("-%s" % damage, Color(1.0, 0.92, 0.42, 1.0), 24, 0.55, Vector2(0.0, -42.0))
	effects_container.add_child(floating_text)


func _spawn_burst(world_position: Vector2) -> void:
	var burst: BurstEffect = BurstEffect.new()
	burst.global_position = world_position
	effects_container.add_child(burst)


func _spawn_wave_popup(text: String) -> void:
	var popup: FloatingText = FloatingText.new()
	popup.global_position = Vector2(960.0, 124.0)
	popup.configure(text, Color(0.72, 0.96, 1.0, 1.0), 38, 0.9, Vector2(0.0, -28.0))
	effects_container.add_child(popup)
