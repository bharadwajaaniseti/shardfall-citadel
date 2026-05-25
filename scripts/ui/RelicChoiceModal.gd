class_name RelicChoiceModal
extends Control

@onready var title_label: Label = %TitleLabel
@onready var relic_buttons: Array = [%RelicButtonA, %RelicButtonB, %RelicButtonC]

var offered_relics: Array = ["echo_chamber", "citadel_heart", "prism_lens"]


func _ready() -> void:
	title_label.text = "Choose a Relic"
	_populate_buttons()


func _populate_buttons() -> void:
	var database: Node = get_node_or_null("/root/GameDatabase")
	for index in range(relic_buttons.size()):
		var button: Button = relic_buttons[index]
		var relic_id: String = String(offered_relics[index])
		var display_name: String = relic_id.capitalize()
		if database != null and database.has_method("get_relic"):
			var relic_data: Dictionary = database.call("get_relic", StringName(relic_id)) as Dictionary
			display_name = String(relic_data.get("display_name", display_name))
		button.text = display_name
		button.pressed.connect(_select_relic.bind(relic_id))


func _select_relic(relic_id: String) -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state != null and run_state.has_method("add_relic"):
		run_state.call("add_relic", StringName(relic_id))
	_change_scene("res://scenes/gameplay/Gameplay.tscn")


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
