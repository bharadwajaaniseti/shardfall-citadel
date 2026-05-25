class_name MainMenu
extends Control

@onready var status_label: Label = %StatusLabel
@onready var start_run_button: Button = %StartRunButton
@onready var hub_button: Button = %HubButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	start_run_button.pressed.connect(_start_run)
	hub_button.pressed.connect(_open_hub)
	settings_button.pressed.connect(_open_settings)
	_refresh_status()


func _refresh_status() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		status_label.text = "Shardfall Citadel\nAutoloads are not available in this preview."
		return

	status_label.text = "Shardfall Citadel\nCitadel Level %s\nShards: %s  Cores: %s" % [
		int(game_state.get("citadel_level")),
		int(game_state.get("shards")),
		int(game_state.get("cores")),
	]


func _start_run() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state != null and run_state.has_method("start_run"):
		run_state.call("start_run", 100, 8, {})
		run_state.call("start_wave", 1, 8)
	_change_scene("res://scenes/gameplay/Gameplay.tscn")


func _open_hub() -> void:
	_change_scene("res://scenes/hub/CitadelHub.tscn")


func _open_settings() -> void:
	_change_scene("res://scenes/ui/SettingsScreen.tscn")


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
