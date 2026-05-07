## Controls the integrated ROV selection page.
## Keeps the existing back-navigation while wiring simulation and Tool
## hardware entry buttons to the merged project scenes.
extends Control

@export var welcome_scene_path: String = "res://Levels/1_WelcomeScene/WelcomScene.tscn"
@export var rov_sim_scene_path: String = "res://Levels/5_rovsim/scenes/main/main.tscn"
@export var serial_scene_path: String = "res://Levels/6_SquareDotSerial/Scenes/Main/MainWorkspace.tscn"


## Returns to the integrated welcome scene.
func _on_backmain_button_pressed() -> void:
	get_tree().change_scene_to_file(welcome_scene_path)


## Opens the integrated ROV simulation scene.
func _on_simulation_button_pressed() -> void:
	get_tree().change_scene_to_file(rov_sim_scene_path)


## Opens the integrated serial Tool scene.
func _on_hardware_button_pressed() -> void:
	get_tree().change_scene_to_file(serial_scene_path)


## Preserves the legacy button signal name used by the original scene.
func _on_button_pressed() -> void:
	_on_simulation_button_pressed()
