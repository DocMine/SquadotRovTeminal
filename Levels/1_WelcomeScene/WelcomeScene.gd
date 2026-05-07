## Controls the integrated welcome scene entry points.
## Binds the main menu buttons to the merged feature scenes and keeps
## the loading transition localized to this page-level controller.
extends Control

@export_node_path("Button") var tool_button_path: NodePath
@export_node_path("Button") var demonstration_button_path: NodePath
@export_node_path("Button") var pid_teach_button_path: NodePath
@export_node_path("Button") var exit_button_path: NodePath
@export_node_path("Button") var rov_sim_button_path: NodePath

@export_category("Scene Paths")
@export var tool_scene_path: String = ""
@export var demonstration_scene_path: String = ""
@export var pid_teach_scene_path: String = ""
@export var rov_sim_scene_path: String = ""
@export var loading_scene: PackedScene

@onready var tool_button: Button = get_node_or_null(tool_button_path) as Button
@onready var demonstration_button: Button = get_node_or_null(demonstration_button_path) as Button
@onready var pid_teach_button: Button = get_node_or_null(pid_teach_button_path) as Button
@onready var exit_button: Button = get_node_or_null(exit_button_path) as Button
@onready var rov_sim_button: Button = get_node_or_null(rov_sim_button_path) as Button
@onready var button_manager: Container = $MarginContainer/AllInfoBox/MarginContainer/Buttonmanager


## Connects the configured buttons and disables entries that do not have
## a valid scene target yet.
func _ready() -> void:
	_connect_button(tool_button, _on_tool_button_pressed)
	_connect_button(demonstration_button, _on_demonstration_button_pressed)
	_connect_button(pid_teach_button, _on_pid_teach_button_pressed)
	_connect_button(exit_button, _on_exit_button_pressed)
	_connect_button(rov_sim_button, _on_rov_sim_button_pressed)
	_set_button_enabled(tool_button, not tool_scene_path.is_empty())
	_set_button_enabled(demonstration_button, not demonstration_scene_path.is_empty())
	_set_button_enabled(pid_teach_button, not pid_teach_scene_path.is_empty())
	_set_button_enabled(rov_sim_button, not rov_sim_scene_path.is_empty())


## Opens the requested target scene.
## Uses the configured loading scene when available; otherwise it switches
## directly to the destination scene file.
func load_to_scene(target_scene_path: String) -> void:
	if target_scene_path.is_empty():
		push_error("WelcomeScene target scene path is empty.")
		return
	if not ResourceLoader.exists(target_scene_path):
		push_error("WelcomeScene target scene does not exist: %s" % target_scene_path)
		return
	if loading_scene == null:
		get_tree().change_scene_to_file(target_scene_path)
		return
	var loading_node: Node = loading_scene.instantiate()
	if loading_node == null or loading_node.get_script() == null:
		get_tree().change_scene_to_file(target_scene_path)
		return
	if button_manager != null and button_manager.has_method("slide_out"):
		await button_manager.slide_out()
	loading_node.set("TargetScenePath", target_scene_path)
	if not scene_file_path.is_empty():
		loading_node.set("BreakScenePath", scene_file_path)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.BLACK, 0.8)
	await tween.finished
	_replace_current_scene(loading_node)


## Routes the Tool button to the serial workspace entry.
func _on_tool_button_pressed() -> void:
	load_to_scene(tool_scene_path)


## Routes the demonstration button to the ROV selection page.
func _on_demonstration_button_pressed() -> void:
	load_to_scene(demonstration_scene_path)


## Routes the PID teach button to the PID teaching scene.
func _on_pid_teach_button_pressed() -> void:
	load_to_scene(pid_teach_scene_path)


## Routes the new ROV sim button to the integrated simulation entry.
func _on_rov_sim_button_pressed() -> void:
	load_to_scene(rov_sim_scene_path)


## Closes the application from the welcome page.
func _on_exit_button_pressed() -> void:
	get_tree().quit()


## Connects a button only once when the node exists.
func _connect_button(button: Button, handler: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(handler):
		button.pressed.connect(handler)


## Enables or disables an entry button based on scene availability.
func _set_button_enabled(button: Button, enabled: bool) -> void:
	if button == null:
		return
	button.disabled = not enabled


## Replaces the active scene with a preconfigured node instance.
## This avoids repacking runtime-instanced loading scenes and preserves
## the injected target path for the loading transition.
func _replace_current_scene(next_scene: Node) -> void:
	var tree: SceneTree = get_tree()
	var root: Window = tree.root
	var current_scene: Node = tree.current_scene
	if current_scene != null:
		root.remove_child(current_scene)
		current_scene.queue_free()
	root.add_child(next_scene)
	tree.current_scene = next_scene
