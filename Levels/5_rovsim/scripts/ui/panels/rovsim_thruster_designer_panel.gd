## Controls the thruster template designer page for the ROV simulator.
## Owns the thruster template parameter inputs and template file actions.
## Mount this script on the `ThrusterDesignerTab` ScrollContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimThrusterDesignerPanel
extends ScrollContainer

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

signal save_thruster_requested
signal load_thruster_requested
signal thruster_template_changed(payload: Dictionary)

@onready var thruster_designer_title: Label = get_node("ThrusterDesignerVBox/ThrusterDesignerTitle") as Label
@onready var save_thruster_button: Button = get_node("ThrusterDesignerVBox/ThrusterActionRow/SaveThrusterButton") as Button
@onready var load_thruster_button: Button = get_node("ThrusterDesignerVBox/ThrusterActionRow/LoadThrusterButton") as Button
@onready var thruster_max_forward_row: LabelSpinRow = get_node("ThrusterDesignerVBox/ThrusterMaxForwardRow") as LabelSpinRow
@onready var thruster_max_reverse_row: LabelSpinRow = get_node("ThrusterDesignerVBox/ThrusterMaxReverseRow") as LabelSpinRow
@onready var thruster_diameter_row: LabelSpinRow = get_node("ThrusterDesignerVBox/ThrusterDiameterRow") as LabelSpinRow
@onready var thruster_length_row: LabelSpinRow = get_node("ThrusterDesignerVBox/ThrusterLengthRow") as LabelSpinRow


## Configures the designer inputs, connects signals, and applies localized texts.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	_configure_controls()
	_connect_internal_signals()
	apply_static_texts()


## Refreshes the static labels shown in the thruster designer page.
## Example:
## `thruster_panel.apply_static_texts()`
func apply_static_texts() -> void:
	thruster_designer_title.text = AppLocalizationScript.translate("THRUSTER_DESIGNER_TITLE")
	save_thruster_button.text = AppLocalizationScript.translate("WORKBENCH_SAVE_THRUSTER")
	load_thruster_button.text = AppLocalizationScript.translate("WORKBENCH_LOAD_THRUSTER")
	thruster_max_forward_row.set_label_text(AppLocalizationScript.translate("THRUSTER_MAX_FORWARD"))
	thruster_max_reverse_row.set_label_text(AppLocalizationScript.translate("THRUSTER_MAX_REVERSE"))
	thruster_diameter_row.set_label_text(AppLocalizationScript.translate("THRUSTER_DIAMETER"))
	thruster_length_row.set_label_text(AppLocalizationScript.translate("THRUSTER_LENGTH"))


## Collects the current thruster template input payload.
## Example:
## `var payload: Dictionary = thruster_panel.get_thruster_template_inputs()`
func get_thruster_template_inputs() -> Dictionary:
	return {
		"max_forward_thrust_n": float(thruster_max_forward_row.get_value_number()),
		"max_reverse_thrust_n": float(thruster_max_reverse_row.get_value_number()),
		"diameter_m": float(thruster_diameter_row.get_value_number()),
		"length_m": float(thruster_length_row.get_value_number()),
	}


## Pushes a loaded thruster template into the designer inputs.
## Example:
## `thruster_panel.set_thruster_template_values(template_resource)`
func set_thruster_template_values(thruster_template: ThrusterTemplate) -> void:
	thruster_max_forward_row.set_value_number(thruster_template.max_forward_thrust_n)
	thruster_max_reverse_row.set_value_number(thruster_template.max_reverse_thrust_n)
	thruster_diameter_row.set_value_number(thruster_template.diameter_m)
	thruster_length_row.set_value_number(thruster_template.length_m)


## Configures the numeric bounds for the thruster template inputs.
func _configure_controls() -> void:
	thruster_max_forward_row.configure(1.0, 300.0, 1.0, false)
	thruster_max_reverse_row.configure(1.0, 300.0, 1.0, false)
	thruster_diameter_row.configure(0.02, 1.0, 0.01, false)
	thruster_length_row.configure(0.02, 2.0, 0.01, false)


## Connects the UI controls to business signals emitted by the designer page.
func _connect_internal_signals() -> void:
	if not save_thruster_button.pressed.is_connected(_on_save_thruster_button_pressed):
		save_thruster_button.pressed.connect(_on_save_thruster_button_pressed)
	if not load_thruster_button.pressed.is_connected(_on_load_thruster_button_pressed):
		load_thruster_button.pressed.connect(_on_load_thruster_button_pressed)
	if not thruster_max_forward_row.value_changed.is_connected(_on_template_value_changed):
		thruster_max_forward_row.value_changed.connect(_on_template_value_changed)
	if not thruster_max_reverse_row.value_changed.is_connected(_on_template_value_changed):
		thruster_max_reverse_row.value_changed.connect(_on_template_value_changed)
	if not thruster_diameter_row.value_changed.is_connected(_on_template_value_changed):
		thruster_diameter_row.value_changed.connect(_on_template_value_changed)
	if not thruster_length_row.value_changed.is_connected(_on_template_value_changed):
		thruster_length_row.value_changed.connect(_on_template_value_changed)


## Emits the save-template business action.
func _on_save_thruster_button_pressed() -> void:
	save_thruster_requested.emit()


## Emits the load-template business action.
func _on_load_thruster_button_pressed() -> void:
	load_thruster_requested.emit()


## Emits the current template payload after any numeric value change.
func _on_template_value_changed(_value: float) -> void:
	thruster_template_changed.emit(get_thruster_template_inputs())
