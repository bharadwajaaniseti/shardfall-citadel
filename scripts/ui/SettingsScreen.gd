class_name SettingsScreen
extends Control

@onready var status_label: Label = %StatusLabel
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	save_button.pressed.connect(_run_save_action.bind("save_game", "Saved game."))
	load_button.pressed.connect(_run_save_action.bind("load_game", "Loaded game."))
	reset_button.pressed.connect(_run_save_action.bind("reset_save", "Reset save."))
	back_button.pressed.connect(_change_scene.bind("res://scenes/ui/MainMenu.tscn"))
	status_label.text = "Settings\nSave file: %s" % ("found" if _has_save_file() else "not found")


func _run_save_action(method_name: String, success_message: String) -> void:
	var save_manager: Node = get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method(method_name):
		status_label.text = "Settings\nSaveManager is unavailable."
		return

	var success: bool = bool(save_manager.call(method_name))
	if success:
		status_label.text = "Settings\n%s" % success_message
	else:
		status_label.text = "Settings\n%s" % String(save_manager.get("last_error"))


func _has_save_file() -> bool:
	var save_manager: Node = get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("has_save_file"):
		return false
	return bool(save_manager.call("has_save_file"))


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
