class_name SkillTree
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
		content_label.text = "Skill Tree\nUpgrade data is unavailable."
		return

	var upgrades: Dictionary = database.call("get_all_upgrades") as Dictionary
	var lines: PackedStringArray = PackedStringArray(["Skill Tree"])
	for upgrade_id in upgrades.keys():
		var upgrade_key: String = String(upgrade_id)
		var upgrade: Dictionary = upgrades[upgrade_id] as Dictionary
		var level: int = 0
		if game_state != null and game_state.has_method("get_upgrade_level"):
			level = int(game_state.call("get_upgrade_level", StringName(upgrade_key)))
		lines.append("%s - Level %s/%s" % [
			String(upgrade.get("display_name", upgrade_key)),
			level,
			int(upgrade.get("max_level", 1)),
		])
	content_label.text = "\n".join(lines)


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
