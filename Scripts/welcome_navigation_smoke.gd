## Smoke-tests the welcome scene navigation routes used by the merged project entry.
## Run with:
## `Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://Scripts/welcome_navigation_smoke.gd`
extends SceneTree

const WELCOME_SCENE_PATH: String = "res://Levels/1_WelcomeScene/WelcomScene.tscn"
const TOOL_SCENE_PATH: String = "res://Levels/6_SquareDotSerial/Scenes/Main/MainWorkspace.tscn"
const DEMONSTRATION_SCENE_PATH: String = "res://Levels/2_RovSelectScene/selection_page.tscn"
const PID_TEACH_SCENE_PATH: String = "res://Levels/4_PIDTeach/scenes/pid_teach.tscn"
const ROV_SIM_SCENE_PATH: String = "res://Levels/5_rovsim/scenes/main/main.tscn"
const ROUTE_TIMEOUT_SECONDS: float = 5.0


## Starts the asynchronous smoke test once the scene tree is ready.
func _init() -> void:
	call_deferred("_run_smoke_test")


## Executes the route validation flow and exits with a non-zero code on failure.
func _run_smoke_test() -> void:
	var failures: PackedStringArray = PackedStringArray()
	failures.append_array(await _validate_route("tool_scene_path", TOOL_SCENE_PATH))
	failures.append_array(await _validate_route("demonstration_scene_path", DEMONSTRATION_SCENE_PATH))
	failures.append_array(await _validate_route("pid_teach_scene_path", PID_TEACH_SCENE_PATH))
	failures.append_array(await _validate_route("rov_sim_scene_path", ROV_SIM_SCENE_PATH))
	_clear_current_scene()
	await process_frame
	if failures.is_empty():
		print("WELCOME_ROUTE_SMOKE_OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


## Loads the welcome scene, overrides one target route, triggers the navigation method,
## and verifies that the active scene switches to the expected destination.
## Example:
## `await _validate_route("tool_scene_path", TOOL_SCENE_PATH)`
func _validate_route(scene_property: String, expected_scene_path: String) -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	_clear_current_scene()
	var welcome_scene: PackedScene = load(WELCOME_SCENE_PATH) as PackedScene
	if welcome_scene == null:
		failures.append("Failed to load welcome scene: %s" % WELCOME_SCENE_PATH)
		return failures
	var welcome_instance: Node = welcome_scene.instantiate()
	if welcome_instance == null:
		failures.append("Failed to instantiate welcome scene: %s" % WELCOME_SCENE_PATH)
		return failures
	get_root().add_child(welcome_instance)
	current_scene = welcome_instance
	await process_frame
	welcome_instance.set(scene_property, expected_scene_path)
	welcome_instance.call("load_to_scene", expected_scene_path)
	await create_timer(ROUTE_TIMEOUT_SECONDS).timeout
	if current_scene == null:
		failures.append("Navigation left the scene tree empty for %s." % expected_scene_path)
		return failures
	if current_scene.scene_file_path != expected_scene_path:
		failures.append(
			"Navigation failed for %s. Active scene: %s" % [
				expected_scene_path,
				current_scene.scene_file_path,
			]
		)
	return failures


## Removes the active scene between route checks so each validation starts cleanly.
func _clear_current_scene() -> void:
	if current_scene == null:
		return
	var scene_to_free: Node = current_scene
	get_root().remove_child(scene_to_free)
	scene_to_free.queue_free()
	current_scene = null
