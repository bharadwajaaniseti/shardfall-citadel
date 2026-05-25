class_name Main
extends Node

@export_file("*.tscn") var startup_scene_path: String = "res://scenes/ui/MainMenu.tscn"

var active_scene: Node


func _ready() -> void:
	_load_save_if_available()
	open_scene(startup_scene_path)


func open_scene(scene_path: String) -> void:
	if active_scene != null:
		active_scene.queue_free()
		active_scene = null

	var resource: Resource = load(scene_path)
	if not (resource is PackedScene):
		push_error("Could not load scene: %s" % scene_path)
		return

	var packed_scene: PackedScene = resource as PackedScene
	active_scene = packed_scene.instantiate()
	add_child(active_scene)


func _load_save_if_available() -> void:
	var save_manager: Node = get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("load_game"):
		save_manager.call("load_game")
