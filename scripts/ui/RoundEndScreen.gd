class_name RoundEndScreen
extends Control

@onready var summary_label: Label = %SummaryLabel
@onready var claim_button: Button = %ClaimButton
@onready var menu_button: Button = %MenuButton

var rewards_claimed: bool = false


func _ready() -> void:
	claim_button.pressed.connect(_claim_rewards)
	menu_button.pressed.connect(_change_scene.bind("res://scenes/ui/MainMenu.tscn"))
	_refresh_summary()


func _claim_rewards() -> void:
	if rewards_claimed:
		return

	var run_state: Node = get_node_or_null("/root/RunState")
	var game_state: Node = get_node_or_null("/root/GameState")
	if run_state == null or game_state == null:
		return

	var rewards_raw: Variant = run_state.get("run_rewards")
	var rewards: Dictionary = {}
	if rewards_raw is Dictionary:
		rewards = rewards_raw as Dictionary
	for reward_id in rewards.keys():
		if game_state.has_method("add_currency"):
			game_state.call("add_currency", StringName(String(reward_id)), int(rewards[reward_id]))

	var save_manager: Node = get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("save_game"):
		save_manager.call("save_game")

	rewards_claimed = true
	claim_button.disabled = true
	_refresh_summary()


func _refresh_summary() -> void:
	var run_state: Node = get_node_or_null("/root/RunState")
	if run_state == null:
		summary_label.text = "Run Complete\nNo run data is available."
		return

	summary_label.text = "Run Complete\nRewards: %s\nClaimed: %s" % [
		str(run_state.get("run_rewards")),
		"Yes" if rewards_claimed else "No",
	]


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
