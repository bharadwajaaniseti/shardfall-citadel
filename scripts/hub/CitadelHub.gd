class_name CitadelHub
extends Control

@onready var summary_label: Label = %SummaryLabel
@onready var forge_button: Button = %ForgeButton
@onready var archive_button: Button = %ArchiveButton
@onready var skills_button: Button = %SkillsButton
@onready var codex_button: Button = %CodexButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	forge_button.pressed.connect(_change_scene.bind("res://scenes/ui/BallForge.tscn"))
	archive_button.pressed.connect(_change_scene.bind("res://scenes/ui/RelicArchive.tscn"))
	skills_button.pressed.connect(_change_scene.bind("res://scenes/ui/SkillTree.tscn"))
	codex_button.pressed.connect(_change_scene.bind("res://scenes/ui/CodexScreen.tscn"))
	menu_button.pressed.connect(_change_scene.bind("res://scenes/ui/MainMenu.tscn"))
	_refresh_summary()


func _refresh_summary() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		summary_label.text = "Citadel Hub\nPersistent progress is unavailable in this preview."
		return

	summary_label.text = "Citadel Hub\nLevel %s\nShards: %s  Dust: %s  Essence: %s" % [
		int(game_state.get("citadel_level")),
		int(game_state.get("shards")),
		int(game_state.get("relic_dust")),
		int(game_state.get("seasonal_essence")),
	]


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
