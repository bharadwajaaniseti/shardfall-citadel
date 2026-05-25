class_name BallForge
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
		content_label.text = "Ball Forge\nBall data is unavailable."
		return

	var balls: Dictionary = database.call("get_all_balls") as Dictionary
	var unlocked: Array = []
	if game_state != null:
		var unlocked_raw: Variant = game_state.get("unlocked_balls")
		if unlocked_raw is Array:
			unlocked = unlocked_raw as Array

	var lines: PackedStringArray = PackedStringArray(["Ball Forge"])
	for ball_id in balls.keys():
		var ball_key: String = String(ball_id)
		var ball: Dictionary = balls[ball_id] as Dictionary
		var owned_marker: String = "unlocked" if unlocked.has(ball_key) else "locked"
		lines.append("%s - %s" % [String(ball.get("display_name", ball_key)), owned_marker])
	content_label.text = "\n".join(lines)


func _change_scene(path: String) -> void:
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s. Error code: %s" % [path, error])
