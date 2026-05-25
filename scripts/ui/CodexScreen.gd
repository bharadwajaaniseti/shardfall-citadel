class_name CodexScreen
extends Control

@onready var content_label: Label = %ContentLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_change_scene.bind("res://scenes/hub/CitadelHub.tscn"))
	_refresh_content()


func _refresh_content() -> void:
	var database: Node = get_node_or_null("/root/GameDatabase")
	if database == null:
		content_label.text = "Codex\nDatabase autoload is unavailable."
		return

	var balls: Dictionary = database.call("get_all_balls") as Dictionary
	var relics: Dictionary = database.call("get_all_relics") as Dictionary
	var blocks: Dictionary = database.call("get_all_blocks") as Dictionary
	var enemies: Dictionary = database.call("get_all_enemies") as Dictionary
	var upgrades: Dictionary = database.call("get_all_upgrades") as Dictionary

	content_label.text = "Codex\nBalls: %s\nRelics: %s\nBlocks: %s\nEnemies: %s\nUpgrades: %s" % [
		balls.size(),
		relics.size(),
		blocks.size(),
		enemies.size(),
		upgrades.size(),
	]


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
