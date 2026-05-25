class_name Gameplay
extends Node2D

@onready var status_label: Label = %StatusLabel
@onready var shoot_button: Button = %ShootButton
@onready var complete_wave_button: Button = %CompleteWaveButton
@onready var end_run_button: Button = %EndRunButton


func _ready() -> void:
	shoot_button.pressed.connect(_spend_test_shot)
	complete_wave_button.pressed.connect(_complete_test_wave)
	end_run_button.pressed.connect(_end_run)

	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state != null and not bool(run_state.get("is_run_active")):
		run_state.call("start_run", 100, 8, {})
		run_state.call("start_wave", 1, 8)

	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("citadel_hp_changed"):
		event_bus.connect("citadel_hp_changed", Callable(self, "_on_citadel_hp_changed"))

	_refresh_status()


func _spend_test_shot() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state != null and run_state.has_method("spend_shot"):
		run_state.call("spend_shot", 1)
	_refresh_status()


func _complete_test_wave() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state == null:
		return

	var wave: int = int(run_state.get("current_wave"))
	run_state.call("complete_wave", {"shards": 10 + wave})
	run_state.call("start_wave", wave + 1, 8)
	_refresh_status()


func _end_run() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state != null and run_state.has_method("end_run"):
		run_state.call("end_run", false)
	_change_scene("res://scenes/ui/RoundEndScreen.tscn")


func _on_citadel_hp_changed(_current_hp: int, _max_hp: int, _delta: int) -> void:
	_refresh_status()


func _refresh_status() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state == null:
		status_label.text = "Gameplay Prototype\nRun state is unavailable."
		return

	status_label.text = "Gameplay Prototype\nWave %s\nCitadel HP: %s/%s\nShots: %s\nRewards: %s" % [
		int(run_state.get("current_wave")),
		int(run_state.get("citadel_hp")),
		int(run_state.get("max_citadel_hp")),
		int(run_state.get("shots_remaining")),
		str(run_state.get("run_rewards")),
	]


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
