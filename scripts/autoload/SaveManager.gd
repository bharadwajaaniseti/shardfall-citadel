class_name SaveManagerAutoload
extends Node

const SAVE_PATH: String = "user://save_data.json"
const SAVE_VERSION: int = 1

var last_error: String = ""


func save_game() -> bool:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("to_save_data"):
		last_error = "GameState autoload is not available."
		push_warning(last_error)
		return false

	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"game_state": game_state.call("to_save_data"),
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open save file for writing. Error code: %s" % FileAccess.get_open_error()
		push_warning(last_error)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	last_error = ""
	return true


func load_game() -> bool:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("apply_save_data"):
		last_error = "GameState autoload is not available."
		push_warning(last_error)
		return false

	if not FileAccess.file_exists(SAVE_PATH):
		_apply_default_state()
		last_error = "No save file found; default state loaded."
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_error = "Could not open save file for reading. Error code: %s" % FileAccess.get_open_error()
		push_warning(last_error)
		_apply_default_state()
		return false

	var json: JSON = JSON.new()
	var parse_error: int = json.parse(file.get_as_text())
	var parsed_data: Variant = json.data
	if parse_error != OK or not (parsed_data is Dictionary):
		last_error = "Save data is corrupted: %s at line %s" % [json.get_error_message(), json.get_error_line()]
		push_warning(last_error)
		_apply_default_state()
		return false

	var loaded_data: Dictionary = parsed_data as Dictionary
	var state_data: Variant = loaded_data.get("game_state", loaded_data)
	if not (state_data is Dictionary):
		last_error = "Save data is missing the GameState payload."
		push_warning(last_error)
		_apply_default_state()
		return false

	game_state.call("apply_save_data", state_data)
	last_error = ""
	return true


func reset_save() -> bool:
	_apply_default_state()

	if not FileAccess.file_exists(SAVE_PATH):
		last_error = ""
		return true

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		last_error = "Could not open the user data directory."
		push_warning(last_error)
		return false

	var remove_error: int = dir.remove("save_data.json")
	if remove_error != OK:
		last_error = "Could not remove save_data.json. Error code: %s" % remove_error
		push_warning(last_error)
		return false

	last_error = ""
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _apply_default_state() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("reset_to_defaults"):
		game_state.call("reset_to_defaults")
