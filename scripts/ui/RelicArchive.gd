class_name RelicArchive
extends Control

@onready var content_label: Label = %ContentLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_change_scene.bind("res://scenes/hub/CitadelHub.tscn"))
	_refresh_content()


func _refresh_content() -> void:
	var database: Node = get_node_or_null("/root/GameDatabase")
	var game_state: Node = get_node_or_null("/root/GameState")
	if database == null:
		content_label.text = "Relic Archive\nRelic data is unavailable."
		return

	var relics: Dictionary = database.call("get_all_relics") as Dictionary
	var unlocked: Array = []
	if game_state != null:
		var unlocked_raw: Variant = game_state.get("unlocked_relics")
		if unlocked_raw is Array:
			unlocked = unlocked_raw as Array

	var lines: PackedStringArray = PackedStringArray(["Relic Archive"])
	for relic_id in relics.keys():
		var relic_key: String = String(relic_id)
		var relic: Dictionary = relics[relic_id] as Dictionary
		var owned_marker: String = "unlocked" if unlocked.has(relic_key) else "undiscovered"
		lines.append("%s - %s" % [String(relic.get("display_name", relic_key)), owned_marker])
	content_label.text = "\n".join(lines)


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
