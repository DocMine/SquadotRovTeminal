## Controls the top toolbar for the integrated ROV simulator.
## Owns the toolbar buttons and status badge inside the RootControl scene.
## Mount this script on the `Toolbar` PanelContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimToolbarPanel
extends PanelContainer

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

signal start_requested
signal record_requested
signal clear_requested

@onready var start_button: Button = get_node("ToolbarMargin/ToolbarRow/StartButton") as Button
@onready var record_button: Button = get_node("ToolbarMargin/ToolbarRow/RecordButton") as Button
@onready var clear_button: Button = get_node("ToolbarMargin/ToolbarRow/ClearButton") as Button
@onready var status_badge: StatusBadge = get_node("ToolbarMargin/ToolbarRow/StatusBadge") as StatusBadge

var _is_sim_running: bool = false
var _is_recording: bool = false


## Connects the toolbar buttons once and applies the initial localized texts.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not record_button.pressed.is_connected(_on_record_button_pressed):
		record_button.pressed.connect(_on_record_button_pressed)
	if not clear_button.pressed.is_connected(_on_clear_button_pressed):
		clear_button.pressed.connect(_on_clear_button_pressed)
	apply_static_texts()


## Refreshes the toolbar button texts for the active locale and current runtime state.
## Example:
## `toolbar_panel.apply_static_texts()`
func apply_static_texts() -> void:
	if _is_sim_running:
		start_button.text = AppLocalizationScript.translate("MAIN_PAUSE_SIM")
	else:
		start_button.text = AppLocalizationScript.translate("MAIN_START_SIM")
	if _is_recording:
		record_button.text = AppLocalizationScript.translate("MAIN_STOP_RECORDING")
	else:
		record_button.text = AppLocalizationScript.translate("MAIN_START_RECORDING")
	clear_button.text = AppLocalizationScript.translate("MAIN_CLEAR")


## Updates the start button according to the simulation running state.
## Example:
## `toolbar_panel.set_sim_running(true)`
func set_sim_running(is_running: bool) -> void:
	_is_sim_running = is_running
	apply_static_texts()


## Updates the record button according to the recorder state.
## Example:
## `toolbar_panel.set_recording(false)`
func set_recording(is_recording: bool) -> void:
	_is_recording = is_recording
	apply_static_texts()


## Applies the current status text and color to the badge.
## Example:
## `toolbar_panel.set_status("Ready", Color.SEA_GREEN)`
func set_status(text_value: String, color_value: Color) -> void:
	status_badge.set_status(text_value, color_value)


## Emits the business signal for the start / pause action.
func _on_start_button_pressed() -> void:
	start_requested.emit()


## Emits the business signal for the record toggle action.
func _on_record_button_pressed() -> void:
	record_requested.emit()


## Emits the business signal for the clear action.
func _on_clear_button_pressed() -> void:
	clear_requested.emit()
