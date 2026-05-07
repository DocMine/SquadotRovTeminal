## Controls the assembly and runtime-control workbench page for the ROV simulator.
## Owns runtime controls, environment settings, machine parameters, and thruster editing UI.
## Mount this script on the `AssemblyTab` ScrollContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimAssemblyPanel
extends ScrollContainer

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

signal save_machine_requested
signal load_machine_requested
signal import_frame_requested
signal clear_frame_requested
signal add_thruster_requested
signal remove_thruster_requested
signal preset_selected(index: int)
signal command_changed(value: float)
signal environment_changed(payload: Dictionary)
signal control_changed(payload: Dictionary)
signal machine_parameters_changed(payload: Dictionary)
signal thruster_selected(index: int)
signal thruster_transform_changed(index: int, position_m: Vector3, rotation_rad: Vector3)

@onready var control_title: Label = get_node("AssemblyVBox/ControlTitle") as Label
@onready var preset_row: LabelOptionRow = get_node("AssemblyVBox/PresetRow") as LabelOptionRow
@onready var command_row: LabelSpinRow = get_node("AssemblyVBox/CommandRow") as LabelSpinRow
@onready var environment_title: Label = get_node("AssemblyVBox/EnvironmentTitle") as Label
@onready var current_mode_row: LabelOptionRow = get_node("AssemblyVBox/CurrentModeRow") as LabelOptionRow
@onready var current_x_row: LabelSpinRow = get_node("AssemblyVBox/CurrentXRow") as LabelSpinRow
@onready var current_z_row: LabelSpinRow = get_node("AssemblyVBox/CurrentZRow") as LabelSpinRow
@onready var turbulence_row: LabelSpinRow = get_node("AssemblyVBox/TurbulenceRow") as LabelSpinRow
@onready var control_system_title: Label = get_node("AssemblyVBox/ControlSystemTitle") as Label
@onready var control_mode_row: LabelOptionRow = get_node("AssemblyVBox/ControlModeRow") as LabelOptionRow
@onready var target_depth_row: LabelSpinRow = get_node("AssemblyVBox/TargetDepthRow") as LabelSpinRow
@onready var target_heading_row: LabelSpinRow = get_node("AssemblyVBox/TargetHeadingRow") as LabelSpinRow
@onready var target_speed_row: LabelSpinRow = get_node("AssemblyVBox/TargetSpeedRow") as LabelSpinRow
@onready var builder_title: Label = get_node("AssemblyVBox/BuilderTitle") as Label
@onready var save_machine_button: Button = get_node("AssemblyVBox/MachineActionRow/SaveMachineButton") as Button
@onready var load_machine_button: Button = get_node("AssemblyVBox/MachineActionRow/LoadMachineButton") as Button
@onready var import_frame_button: Button = get_node("AssemblyVBox/FrameActionRow/ImportFrameButton") as Button
@onready var clear_frame_button: Button = get_node("AssemblyVBox/FrameActionRow/ClearFrameButton") as Button
@onready var frame_path_row: LabelValueRow = get_node("AssemblyVBox/FramePathRow") as LabelValueRow
@onready var machine_mass_row: LabelSpinRow = get_node("AssemblyVBox/MachineMassRow") as LabelSpinRow
@onready var machine_volume_row: LabelSpinRow = get_node("AssemblyVBox/MachineVolumeRow") as LabelSpinRow
@onready var machine_com_y_row: LabelSpinRow = get_node("AssemblyVBox/MachineComYRow") as LabelSpinRow
@onready var machine_cob_y_row: LabelSpinRow = get_node("AssemblyVBox/MachineCobYRow") as LabelSpinRow
@onready var add_thruster_button: Button = get_node("AssemblyVBox/BuilderButtonRow/AddThrusterButton") as Button
@onready var remove_thruster_button: Button = get_node("AssemblyVBox/BuilderButtonRow/RemoveThrusterButton") as Button
@onready var thruster_title: Label = get_node("AssemblyVBox/ThrusterTitle") as Label
@onready var thruster_list: VBoxContainer = get_node("AssemblyVBox/ThrusterList") as VBoxContainer
@onready var selected_thruster_title: Label = get_node("AssemblyVBox/SelectedThrusterTitle") as Label
@onready var selected_thruster_row: LabelValueRow = get_node("AssemblyVBox/SelectedThrusterRow") as LabelValueRow
@onready var thruster_position_x_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterPositionXRow") as LabelSpinRow
@onready var thruster_position_y_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterPositionYRow") as LabelSpinRow
@onready var thruster_position_z_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterPositionZRow") as LabelSpinRow
@onready var thruster_rotation_x_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterRotationXRow") as LabelSpinRow
@onready var thruster_rotation_y_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterRotationYRow") as LabelSpinRow
@onready var thruster_rotation_z_row: LabelSpinRow = get_node("AssemblyVBox/ThrusterRotationZRow") as LabelSpinRow

var _selected_thruster_index: int = -1
var _is_syncing_thruster_editor: bool = false
var _editor_rows: Array[Dictionary] = []


## Configures row ranges, wires business signals, and applies the initial localized texts.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	_configure_controls()
	_connect_internal_signals()
	apply_static_texts()


## Refreshes all static labels and options for the current locale.
## Example:
## `assembly_panel.apply_static_texts()`
func apply_static_texts() -> void:
	control_title.text = AppLocalizationScript.translate("MAIN_CONTROL_TITLE")
	environment_title.text = AppLocalizationScript.translate("ENVIRONMENT_TITLE")
	control_system_title.text = AppLocalizationScript.translate("CONTROL_SYSTEM_TITLE")
	builder_title.text = AppLocalizationScript.translate("MAIN_BUILDER_TITLE")
	thruster_title.text = AppLocalizationScript.translate("MAIN_THRUSTER_TITLE")
	selected_thruster_title.text = AppLocalizationScript.translate("ASSEMBLY_SELECTED_THRUSTER")
	save_machine_button.text = AppLocalizationScript.translate("WORKBENCH_SAVE_MACHINE")
	load_machine_button.text = AppLocalizationScript.translate("WORKBENCH_LOAD_MACHINE")
	import_frame_button.text = AppLocalizationScript.translate("ASSEMBLY_IMPORT_FRAME")
	clear_frame_button.text = AppLocalizationScript.translate("ASSEMBLY_CLEAR_FRAME")
	add_thruster_button.text = AppLocalizationScript.translate("MAIN_ADD_THRUSTER")
	remove_thruster_button.text = AppLocalizationScript.translate("MAIN_REMOVE_LAST_THRUSTER")
	preset_row.set_label_text(AppLocalizationScript.translate("MAIN_PRESET"))
	command_row.set_label_text(AppLocalizationScript.translate("MAIN_THRUSTER_COMMAND"))
	current_mode_row.set_label_text(AppLocalizationScript.translate("CURRENT_MODE"))
	current_x_row.set_label_text(AppLocalizationScript.translate("CURRENT_X"))
	current_z_row.set_label_text(AppLocalizationScript.translate("CURRENT_Z"))
	turbulence_row.set_label_text(AppLocalizationScript.translate("TURBULENCE_STRENGTH"))
	control_mode_row.set_label_text(AppLocalizationScript.translate("CONTROL_MODE"))
	target_depth_row.set_label_text(AppLocalizationScript.translate("TARGET_DEPTH"))
	target_heading_row.set_label_text(AppLocalizationScript.translate("TARGET_HEADING"))
	target_speed_row.set_label_text(AppLocalizationScript.translate("TARGET_SPEED"))
	frame_path_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_FRAME_PATH"))
	machine_mass_row.set_label_text(AppLocalizationScript.translate("MACHINE_MASS"))
	machine_volume_row.set_label_text(AppLocalizationScript.translate("MACHINE_VOLUME"))
	machine_com_y_row.set_label_text(AppLocalizationScript.translate("MACHINE_COM_Y"))
	machine_cob_y_row.set_label_text(AppLocalizationScript.translate("MACHINE_COB_Y"))
	selected_thruster_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_SELECTED_THRUSTER"))
	thruster_position_x_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_POS_X"))
	thruster_position_y_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_POS_Y"))
	thruster_position_z_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_POS_Z"))
	thruster_rotation_x_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_ROT_X"))
	thruster_rotation_y_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_ROT_Y"))
	thruster_rotation_z_row.set_label_text(AppLocalizationScript.translate("ASSEMBLY_THRUSTER_ROT_Z"))
	_set_localized_options(current_mode_row, PackedStringArray(["CURRENT_MODE_CONSTANT", "CURRENT_MODE_LAYERED", "CURRENT_MODE_TURBULENT"]))
	_set_localized_options(control_mode_row, PackedStringArray(["CONTROL_MODE_MANUAL", "CONTROL_MODE_DEPTH_HOLD", "CONTROL_MODE_HEADING_HOLD", "CONTROL_MODE_STABILIZE"]))
	if not _editor_rows.is_empty():
		set_thruster_editor_rows(_editor_rows, _selected_thruster_index)
	else:
		_update_selected_thruster_editor({})


## Sets the visible preset options in the runtime control section.
## Example:
## `assembly_panel.set_preset_options(titles)`
func set_preset_options(titles: PackedStringArray) -> void:
	preset_row.set_options(titles)
	preset_row.select_index(0)


## Returns the current manual thrust command value.
## Example:
## `var command_value: float = assembly_panel.get_command_value()`
func get_command_value() -> float:
	return float(command_row.get_value_number())


## Collects the environment settings for the simulator runtime.
## Example:
## `var env: Dictionary = assembly_panel.get_environment_inputs()`
func get_environment_inputs() -> Dictionary:
	return {
		"mode": int(current_mode_row.get_selected_index()),
		"current_x_mps": float(current_x_row.get_value_number()),
		"current_z_mps": float(current_z_row.get_value_number()),
		"turbulence": float(turbulence_row.get_value_number()),
	}


## Collects the control system settings for the simulator runtime.
## Example:
## `var control: Dictionary = assembly_panel.get_control_inputs()`
func get_control_inputs() -> Dictionary:
	return {
		"mode": int(control_mode_row.get_selected_index()),
		"target_depth_m": float(target_depth_row.get_value_number()),
		"target_heading_deg": float(target_heading_row.get_value_number()),
		"target_speed_mps": float(target_speed_row.get_value_number()),
	}


## Collects the current machine parameter inputs from the assembly page.
## Example:
## `var machine_inputs: Dictionary = assembly_panel.get_machine_parameter_inputs()`
func get_machine_parameter_inputs() -> Dictionary:
	return {
		"mass_kg": float(machine_mass_row.get_value_number()),
		"volume_m3": float(machine_volume_row.get_value_number()),
		"com_y": float(machine_com_y_row.get_value_number()),
		"cob_y": float(machine_cob_y_row.get_value_number()),
	}


## Pushes the machine parameter values into the assembly inputs.
## Example:
## `assembly_panel.set_machine_parameter_values(machine_payload)`
func set_machine_parameter_values(machine: Dictionary) -> void:
	var center_of_mass: Vector3 = machine.get("center_of_mass_m", Vector3.ZERO)
	var center_of_buoyancy: Vector3 = machine.get("center_of_buoyancy_m", Vector3.ZERO)
	machine_mass_row.set_value_number(float(machine.get("mass_kg", 50.0)))
	machine_volume_row.set_value_number(float(machine.get("displaced_volume_m3", 0.051)))
	machine_com_y_row.set_value_number(center_of_mass.y)
	machine_cob_y_row.set_value_number(center_of_buoyancy.y)


## Updates the visible frame path row for the current imported machine frame.
## Example:
## `assembly_panel.set_frame_path("C:/rovsim/frame.glb")`
func set_frame_path(path: String) -> void:
	frame_path_row.set_value_text(path)


## Rebuilds the thruster editor list using the provided runtime rows.
## Example:
## `assembly_panel.set_thruster_editor_rows(rows, 0)`
func set_thruster_editor_rows(editor_rows: Array[Dictionary], selected_index: int) -> void:
	_editor_rows = editor_rows.duplicate(true)
	for child: Node in thruster_list.get_children():
		child.queue_free()
	if editor_rows.is_empty():
		_selected_thruster_index = -1
		_update_selected_thruster_editor({})
		return
	_selected_thruster_index = clampi(selected_index, 0, editor_rows.size() - 1)
	for editor_row: Dictionary in editor_rows:
		var row_button: Button = Button.new()
		var row_index: int = int(editor_row.get("index", 0))
		var position: Vector3 = editor_row.get("position_m", Vector3.ZERO)
		var direction: Vector3 = editor_row.get("force_direction", Vector3.ZERO)
		row_button.text = AppLocalizationScript.translate("THRUSTER_EDITOR_ROW_FORMAT") % [
			str(editor_row.get("display_name", "")),
			position.x,
			position.y,
			position.z,
			direction.x,
			direction.y,
			direction.z,
		]
		row_button.toggle_mode = true
		row_button.button_pressed = row_index == _selected_thruster_index
		row_button.pressed.connect(func() -> void:
			_selected_thruster_index = row_index
			thruster_selected.emit(row_index)
		)
		thruster_list.add_child(row_button)
	for editor_row: Dictionary in editor_rows:
		if int(editor_row.get("index", -1)) == _selected_thruster_index:
			_update_selected_thruster_editor(editor_row)
			return
	_update_selected_thruster_editor({})


## Configures the numeric controls used by the assembly page.
func _configure_controls() -> void:
	command_row.configure(-1.0, 1.0, 0.01, false)
	command_row.set_value_number(0.45)
	current_mode_row.select_index(0)
	current_x_row.configure(-2.0, 2.0, 0.01, false)
	current_x_row.set_value_number(0.0)
	current_z_row.configure(-2.0, 2.0, 0.01, false)
	current_z_row.set_value_number(0.0)
	turbulence_row.configure(0.0, 1.0, 0.01, false)
	turbulence_row.set_value_number(0.0)
	control_mode_row.select_index(0)
	target_depth_row.configure(0.0, 50.0, 0.1, false)
	target_depth_row.set_value_number(1.2)
	target_heading_row.configure(-180.0, 180.0, 1.0, false)
	target_heading_row.set_value_number(0.0)
	target_speed_row.configure(0.0, 5.0, 0.05, false)
	target_speed_row.set_value_number(0.0)
	machine_mass_row.configure(1.0, 500.0, 0.5, false)
	machine_volume_row.configure(0.001, 1.0, 0.001, false)
	machine_com_y_row.configure(-1.0, 1.0, 0.01, false)
	machine_cob_y_row.configure(-1.0, 1.0, 0.01, false)
	thruster_position_x_row.configure(-4.0, 4.0, 0.01, false)
	thruster_position_y_row.configure(-4.0, 4.0, 0.01, false)
	thruster_position_z_row.configure(-4.0, 4.0, 0.01, false)
	thruster_rotation_x_row.configure(-180.0, 180.0, 1.0, false)
	thruster_rotation_y_row.configure(-180.0, 180.0, 1.0, false)
	thruster_rotation_z_row.configure(-180.0, 180.0, 1.0, false)


## Wires UI controls to business signals emitted by the assembly page.
func _connect_internal_signals() -> void:
	if not save_machine_button.pressed.is_connected(_on_save_machine_button_pressed):
		save_machine_button.pressed.connect(_on_save_machine_button_pressed)
	if not load_machine_button.pressed.is_connected(_on_load_machine_button_pressed):
		load_machine_button.pressed.connect(_on_load_machine_button_pressed)
	if not import_frame_button.pressed.is_connected(_on_import_frame_button_pressed):
		import_frame_button.pressed.connect(_on_import_frame_button_pressed)
	if not clear_frame_button.pressed.is_connected(_on_clear_frame_button_pressed):
		clear_frame_button.pressed.connect(_on_clear_frame_button_pressed)
	if not add_thruster_button.pressed.is_connected(_on_add_thruster_button_pressed):
		add_thruster_button.pressed.connect(_on_add_thruster_button_pressed)
	if not remove_thruster_button.pressed.is_connected(_on_remove_thruster_button_pressed):
		remove_thruster_button.pressed.connect(_on_remove_thruster_button_pressed)
	if not preset_row.option_selected.is_connected(_on_preset_option_selected):
		preset_row.option_selected.connect(_on_preset_option_selected)
	if not command_row.value_changed.is_connected(_on_command_value_changed):
		command_row.value_changed.connect(_on_command_value_changed)
	if not current_mode_row.option_selected.is_connected(_on_environment_control_changed):
		current_mode_row.option_selected.connect(_on_environment_control_changed)
	if not current_x_row.value_changed.is_connected(_on_environment_value_changed):
		current_x_row.value_changed.connect(_on_environment_value_changed)
	if not current_z_row.value_changed.is_connected(_on_environment_value_changed):
		current_z_row.value_changed.connect(_on_environment_value_changed)
	if not turbulence_row.value_changed.is_connected(_on_environment_value_changed):
		turbulence_row.value_changed.connect(_on_environment_value_changed)
	if not control_mode_row.option_selected.is_connected(_on_control_mode_changed):
		control_mode_row.option_selected.connect(_on_control_mode_changed)
	if not target_depth_row.value_changed.is_connected(_on_control_value_changed):
		target_depth_row.value_changed.connect(_on_control_value_changed)
	if not target_heading_row.value_changed.is_connected(_on_control_value_changed):
		target_heading_row.value_changed.connect(_on_control_value_changed)
	if not target_speed_row.value_changed.is_connected(_on_control_value_changed):
		target_speed_row.value_changed.connect(_on_control_value_changed)
	if not machine_mass_row.value_changed.is_connected(_on_machine_parameter_changed):
		machine_mass_row.value_changed.connect(_on_machine_parameter_changed)
	if not machine_volume_row.value_changed.is_connected(_on_machine_parameter_changed):
		machine_volume_row.value_changed.connect(_on_machine_parameter_changed)
	if not machine_com_y_row.value_changed.is_connected(_on_machine_parameter_changed):
		machine_com_y_row.value_changed.connect(_on_machine_parameter_changed)
	if not machine_cob_y_row.value_changed.is_connected(_on_machine_parameter_changed):
		machine_cob_y_row.value_changed.connect(_on_machine_parameter_changed)
	if not thruster_position_x_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_position_x_row.value_changed.connect(_on_thruster_transform_input_changed)
	if not thruster_position_y_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_position_y_row.value_changed.connect(_on_thruster_transform_input_changed)
	if not thruster_position_z_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_position_z_row.value_changed.connect(_on_thruster_transform_input_changed)
	if not thruster_rotation_x_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_rotation_x_row.value_changed.connect(_on_thruster_transform_input_changed)
	if not thruster_rotation_y_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_rotation_y_row.value_changed.connect(_on_thruster_transform_input_changed)
	if not thruster_rotation_z_row.value_changed.is_connected(_on_thruster_transform_input_changed):
		thruster_rotation_z_row.value_changed.connect(_on_thruster_transform_input_changed)


## Updates the selected thruster detail editor from the current row payload.
func _update_selected_thruster_editor(row: Dictionary) -> void:
	_is_syncing_thruster_editor = true
	if row.is_empty():
		selected_thruster_row.set_value_text(AppLocalizationScript.translate("ASSEMBLY_NO_THRUSTER_SELECTED"))
		thruster_position_x_row.set_value_number(0.0)
		thruster_position_y_row.set_value_number(0.0)
		thruster_position_z_row.set_value_number(0.0)
		thruster_rotation_x_row.set_value_number(0.0)
		thruster_rotation_y_row.set_value_number(0.0)
		thruster_rotation_z_row.set_value_number(0.0)
		_is_syncing_thruster_editor = false
		return
	var position: Vector3 = row.get("position_m", Vector3.ZERO)
	var rotation: Vector3 = row.get("rotation_rad", Vector3.ZERO)
	var direction: Vector3 = row.get("force_direction", Vector3.ZERO)
	selected_thruster_row.set_value_text(AppLocalizationScript.translate("ASSEMBLY_SELECTED_THRUSTER_FORMAT") % [
		str(row.get("display_name", "")),
		direction.x,
		direction.y,
		direction.z,
	])
	thruster_position_x_row.set_value_number(position.x)
	thruster_position_y_row.set_value_number(position.y)
	thruster_position_z_row.set_value_number(position.z)
	thruster_rotation_x_row.set_value_number(rad_to_deg(rotation.x))
	thruster_rotation_y_row.set_value_number(rad_to_deg(rotation.y))
	thruster_rotation_z_row.set_value_number(rad_to_deg(rotation.z))
	_is_syncing_thruster_editor = false


## Rebuilds an option row using translated text while preserving the current selection.
func _set_localized_options(row: LabelOptionRow, keys: PackedStringArray) -> void:
	var selected_index: int = int(row.get_selected_index())
	var values: PackedStringArray = PackedStringArray()
	for key: String in keys:
		values.append(AppLocalizationScript.translate(key))
	row.set_options(values)
	if selected_index < 0:
		selected_index = 0
	row.select_index(mini(selected_index, keys.size() - 1))


## Emits the machine-save business action.
func _on_save_machine_button_pressed() -> void:
	save_machine_requested.emit()


## Emits the machine-load business action.
func _on_load_machine_button_pressed() -> void:
	load_machine_requested.emit()


## Emits the frame-import business action.
func _on_import_frame_button_pressed() -> void:
	import_frame_requested.emit()


## Emits the frame-clear business action.
func _on_clear_frame_button_pressed() -> void:
	clear_frame_requested.emit()


## Emits the add-thruster business action.
func _on_add_thruster_button_pressed() -> void:
	add_thruster_requested.emit()


## Emits the remove-thruster business action.
func _on_remove_thruster_button_pressed() -> void:
	remove_thruster_requested.emit()


## Emits the selected preset index.
func _on_preset_option_selected(index: int) -> void:
	preset_selected.emit(index)


## Emits the current manual thrust command value.
func _on_command_value_changed(value: float) -> void:
	command_changed.emit(value)


## Emits the environment payload after an option row change.
func _on_environment_control_changed(_index: int) -> void:
	environment_changed.emit(get_environment_inputs())


## Emits the environment payload after a numeric row change.
func _on_environment_value_changed(_value: float) -> void:
	environment_changed.emit(get_environment_inputs())


## Emits the control payload after a control mode change.
func _on_control_mode_changed(_index: int) -> void:
	control_changed.emit(get_control_inputs())


## Emits the control payload after a numeric control value change.
func _on_control_value_changed(_value: float) -> void:
	control_changed.emit(get_control_inputs())


## Emits the machine parameter payload after a machine field change.
func _on_machine_parameter_changed(_value: float) -> void:
	machine_parameters_changed.emit(get_machine_parameter_inputs())


## Emits the selected thruster transform when the editor fields change.
func _on_thruster_transform_input_changed(_value: float) -> void:
	if _is_syncing_thruster_editor or _selected_thruster_index < 0:
		return
	var position: Vector3 = Vector3(
		float(thruster_position_x_row.get_value_number()),
		float(thruster_position_y_row.get_value_number()),
		float(thruster_position_z_row.get_value_number())
	)
	var rotation: Vector3 = Vector3(
		deg_to_rad(float(thruster_rotation_x_row.get_value_number())),
		deg_to_rad(float(thruster_rotation_y_row.get_value_number())),
		deg_to_rad(float(thruster_rotation_z_row.get_value_number()))
	)
	thruster_transform_changed.emit(_selected_thruster_index, position, rotation)
