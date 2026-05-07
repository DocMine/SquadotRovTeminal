## Aggregates the page-level UI panels used by the integrated ROV simulator scene.
## Keeps `ROVSimMain` isolated from UI leaf nodes by exposing a stable panel-level API,
## forwarding business signals, and delegating localized UI refreshes to the child panels.
## Mount this script on the `RootControl` node in `scenes/main/main.tscn`.
class_name ROVSimRootControl
extends Control

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")
const TAB_INDEX_SIMULATION: int = 0
const TAB_INDEX_CHARTS: int = 3
const TAB_TITLE_KEYS: Array[String] = [
	"TAB_SIMULATION",
	"TAB_ASSEMBLY",
	"TAB_THRUSTER_DESIGNER",
	"TAB_CHARTS",
]

signal start_requested
signal record_requested
signal clear_requested
signal clear_frame_requested
signal request_file_path(operation: String, category: String, file_name: String, filters: PackedStringArray, save_mode: bool)
signal add_thruster_requested
signal remove_thruster_requested
signal preset_selected(index: int)
signal command_changed(value: float)
signal environment_changed(payload: Dictionary)
signal control_changed(payload: Dictionary)
signal machine_parameters_changed(payload: Dictionary)
signal thruster_template_changed(payload: Dictionary)
signal thruster_selected(index: int)
signal thruster_transform_changed(index: int, position_m: Vector3, rotation_rad: Vector3)
signal file_path_selected(path: String)
signal playback_frame_selected(index: int)

@export_node_path("TabContainer") var workbench_tabs_path: NodePath = NodePath("RootVBox/BodyRow/WorkbenchTabs")
@export_node_path("PanelContainer") var toolbar_panel_path: NodePath = NodePath("RootVBox/Toolbar")
@export_node_path("PanelContainer") var resource_panel_path: NodePath = NodePath("RootVBox/BodyRow/ResourcePanel")
@export_node_path("Control") var simulation_tab_path: NodePath = NodePath("RootVBox/BodyRow/WorkbenchTabs/SimulationTab")
@export_node_path("ScrollContainer") var assembly_panel_path: NodePath = NodePath("RootVBox/BodyRow/WorkbenchTabs/AssemblyTab")
@export_node_path("ScrollContainer") var thruster_designer_panel_path: NodePath = NodePath("RootVBox/BodyRow/WorkbenchTabs/ThrusterDesignerTab")
@export_node_path("Control") var chart_workspace_path: NodePath = NodePath("RootVBox/BodyRow/WorkbenchTabs/ChartsTab")
@export_node_path("PanelContainer") var dashboard_panel_path: NodePath = NodePath("RootVBox/BodyRow/InspectorPanel")
@export_node_path("PanelContainer") var status_bar_panel_path: NodePath = NodePath("RootVBox/StatusBar")

@onready var workbench_tabs: TabContainer = get_node(workbench_tabs_path) as TabContainer
@onready var toolbar_panel: ROVSimToolbarPanel = get_node(toolbar_panel_path) as ROVSimToolbarPanel
@onready var resource_panel: ROVSimResourcePanel = get_node(resource_panel_path) as ROVSimResourcePanel
@onready var simulation_tab: ROVSimSimulationTab = get_node(simulation_tab_path) as ROVSimSimulationTab
@onready var assembly_panel: ROVSimAssemblyPanel = get_node(assembly_panel_path) as ROVSimAssemblyPanel
@onready var thruster_designer_panel: ROVSimThrusterDesignerPanel = get_node(thruster_designer_panel_path) as ROVSimThrusterDesignerPanel
@onready var chart_workspace: ROVSimChartWorkspace = get_node(chart_workspace_path) as ROVSimChartWorkspace
@onready var dashboard_panel: ROVSimDashboardPanel = get_node(dashboard_panel_path) as ROVSimDashboardPanel
@onready var status_bar_panel: ROVSimStatusBarPanel = get_node(status_bar_panel_path) as ROVSimStatusBarPanel


## Connects child panel signals and applies the initial localized UI state.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	_connect_child_signals()
	apply_static_texts()


## Refreshes the localized text owned by `RootControl` and its page-level child panels.
## Example:
## `root_control.apply_static_texts()`
func apply_static_texts() -> void:
	for index: int in range(mini(workbench_tabs.get_tab_count(), TAB_TITLE_KEYS.size())):
		workbench_tabs.set_tab_title(index, AppLocalizationScript.translate(TAB_TITLE_KEYS[index]))
	toolbar_panel.apply_static_texts()
	resource_panel.apply_static_texts()
	simulation_tab.apply_static_texts()
	assembly_panel.apply_static_texts()
	thruster_designer_panel.apply_static_texts()
	chart_workspace.apply_static_texts()
	dashboard_panel.apply_static_texts()


## Returns whether the mouse pointer is inside the active 3D simulation workspace.
## Example:
## `if root_control.is_3d_simulation_pointer_active(event.position):`
func is_3d_simulation_pointer_active(screen_position: Vector2) -> bool:
	if not is_3d_simulation_tab_active():
		return false
	return simulation_tab.is_pointer_active(screen_position)


## Returns whether the simulation tab is currently visible.
## Example:
## `if root_control.is_3d_simulation_tab_active():`
func is_3d_simulation_tab_active() -> bool:
	return workbench_tabs.current_tab == TAB_INDEX_SIMULATION


## Returns whether the charts tab is currently visible.
## Example:
## `if root_control.is_charts_tab_active():`
func is_charts_tab_active() -> bool:
	return workbench_tabs.current_tab == TAB_INDEX_CHARTS


## Passes preset option titles into the assembly workbench page.
## Example:
## `root_control.set_preset_options(titles)`
func set_preset_options(titles: PackedStringArray) -> void:
	assembly_panel.set_preset_options(titles)


## Returns the current manual thruster command value from the assembly page.
## Example:
## `var command_value: float = root_control.get_command_value()`
func get_command_value() -> float:
	return assembly_panel.get_command_value()


## Returns the current environment settings collected from the assembly page.
## Example:
## `var environment_inputs: Dictionary = root_control.get_environment_inputs()`
func get_environment_inputs() -> Dictionary:
	return assembly_panel.get_environment_inputs()


## Returns the current control-system settings collected from the assembly page.
## Example:
## `var control_inputs: Dictionary = root_control.get_control_inputs()`
func get_control_inputs() -> Dictionary:
	return assembly_panel.get_control_inputs()


## Opens the shared file dialog panel while preserving the stable `main.gd` call signature.
## Example:
## `root_control.request_file("save_record", path, filters, true)`
func request_file(_operation: String, default_path: String, filters: PackedStringArray, save_mode: bool) -> void:
	resource_panel.request_file(default_path, filters, save_mode)


## Updates the toolbar start button to match the simulator running state.
## Example:
## `root_control.set_sim_running(true)`
func set_sim_running(is_running: bool) -> void:
	toolbar_panel.set_sim_running(is_running)


## Updates the toolbar record button to match recorder state.
## Example:
## `root_control.set_recording(false)`
func set_recording(is_recording: bool) -> void:
	toolbar_panel.set_recording(is_recording)


## Updates both the toolbar badge and bottom status bar text.
## Example:
## `root_control.set_status("Ready", Color.SEA_GREEN)`
func set_status(text_value: String, color_value: Color) -> void:
	toolbar_panel.set_status(text_value, color_value)
	status_bar_panel.set_status_text(text_value)


## Pushes a loaded record summary into the playback panel.
## Example:
## `root_control.set_record_loaded(path, 120)`
func set_record_loaded(path: String, frame_count: int) -> void:
	resource_panel.set_record_loaded(path, frame_count)


## Updates the playback frame summary shown in the resource panel.
## Example:
## `root_control.set_playback_frame(2, 30, 1.42)`
func set_playback_frame(index: int, total: int, depth_m: float) -> void:
	resource_panel.set_playback_frame(index, total, depth_m)


## Clears the playback frame summary shown in the resource panel.
## Example:
## `root_control.set_empty_playback_frame()`
func set_empty_playback_frame() -> void:
	resource_panel.set_empty_playback_frame()


## Pushes the active thruster template into the thruster designer page.
## Example:
## `root_control.set_thruster_template_values(template_resource)`
func set_thruster_template_values(thruster_template: ThrusterTemplate) -> void:
	thruster_designer_panel.set_thruster_template_values(thruster_template)


## Pushes the current machine parameters into the assembly page.
## Example:
## `root_control.set_machine_parameter_values(machine_payload)`
func set_machine_parameter_values(machine: Dictionary) -> void:
	assembly_panel.set_machine_parameter_values(machine)


## Updates all resource-path rows across the resource page and assembly frame row.
## Example:
## `root_control.set_resource_paths(payload)`
func set_resource_paths(payload: Dictionary) -> void:
	resource_panel.set_resource_paths(payload)
	assembly_panel.set_frame_path(str(payload.get("frame_path", "")))


## Pushes the latest dashboard payload into the live inspector panel.
## Example:
## `root_control.set_dashboard(snapshot_payload)`
func set_dashboard(payload: Dictionary) -> void:
	dashboard_panel.set_dashboard(payload)


## Rebuilds the thruster editor list in the assembly page.
## Example:
## `root_control.set_thruster_editor_rows(rows, 0)`
func set_thruster_editor_rows(editor_rows: Array[Dictionary], selected_index: int) -> void:
	assembly_panel.set_thruster_editor_rows(editor_rows, selected_index)


## Pushes the latest chart series into the chart workspace.
## Example:
## `root_control.set_chart_series(chart_payload)`
func set_chart_series(payload: Dictionary) -> void:
	chart_workspace.set_chart_series(payload)


## Clears all realtime chart widgets in the chart workspace.
## Example:
## `root_control.reset_chart_series()`
func reset_chart_series() -> void:
	chart_workspace.reset_chart_series()


## Updates the evaluation report lines shown in the resource panel.
## Example:
## `root_control.set_report_lines(lines)`
func set_report_lines(lines: PackedStringArray) -> void:
	resource_panel.set_report_lines(lines)


## Wires page-level child panel signals into the stable RootControl business API.
func _connect_child_signals() -> void:
	toolbar_panel.start_requested.connect(func() -> void: start_requested.emit())
	toolbar_panel.record_requested.connect(func() -> void: record_requested.emit())
	toolbar_panel.clear_requested.connect(func() -> void: clear_requested.emit())

	resource_panel.save_record_requested.connect(func() -> void:
		_emit_file_request("save_record", "records", "session.rovrecord.json", {"*.rovrecord.json": "FILE_FILTER_ROV_RECORD"}, true)
	)
	resource_panel.load_record_requested.connect(func() -> void:
		_emit_file_request("load_record", "records", "session.rovrecord.json", {"*.rovrecord.json": "FILE_FILTER_ROV_RECORD"}, false)
	)
	resource_panel.export_csv_requested.connect(func() -> void:
		_emit_file_request("export_csv", "exports", "session.csv", {"*.csv": "FILE_FILTER_CSV"}, true)
	)
	resource_panel.file_path_selected.connect(func(path: String) -> void: file_path_selected.emit(path))
	resource_panel.playback_frame_selected.connect(func(index: int) -> void: playback_frame_selected.emit(index))

	assembly_panel.save_machine_requested.connect(func() -> void:
		_emit_file_request("save_machine", "machines", "active.rovmachine.json", {"*.rovmachine.json": "FILE_FILTER_ROV_MACHINE"}, true)
	)
	assembly_panel.load_machine_requested.connect(func() -> void:
		_emit_file_request("load_machine", "machines", "active.rovmachine.json", {"*.rovmachine.json": "FILE_FILTER_ROV_MACHINE"}, false)
	)
	assembly_panel.import_frame_requested.connect(func() -> void:
		_emit_file_request(
			"import_frame",
			"projects",
			"frame.glb",
			{
				"*.glb,*.gltf": "FILE_FILTER_3D_FRAME",
				"*.tscn,*.scn,*.res,*.tres": "FILE_FILTER_GODOT_RESOURCE",
			},
			false
		)
	)
	assembly_panel.clear_frame_requested.connect(func() -> void: clear_frame_requested.emit())
	assembly_panel.add_thruster_requested.connect(func() -> void: add_thruster_requested.emit())
	assembly_panel.remove_thruster_requested.connect(func() -> void: remove_thruster_requested.emit())
	assembly_panel.preset_selected.connect(func(index: int) -> void: preset_selected.emit(index))
	assembly_panel.command_changed.connect(func(value: float) -> void: command_changed.emit(value))
	assembly_panel.environment_changed.connect(func(payload: Dictionary) -> void: environment_changed.emit(payload))
	assembly_panel.control_changed.connect(func(payload: Dictionary) -> void: control_changed.emit(payload))
	assembly_panel.machine_parameters_changed.connect(func(payload: Dictionary) -> void: machine_parameters_changed.emit(payload))
	assembly_panel.thruster_selected.connect(func(index: int) -> void: thruster_selected.emit(index))
	assembly_panel.thruster_transform_changed.connect(func(index: int, position_m: Vector3, rotation_rad: Vector3) -> void:
		thruster_transform_changed.emit(index, position_m, rotation_rad)
	)

	thruster_designer_panel.save_thruster_requested.connect(func() -> void:
		_emit_file_request("save_thruster", "thrusters", "template.rovthruster.json", {"*.rovthruster.json": "FILE_FILTER_ROV_THRUSTER"}, true)
	)
	thruster_designer_panel.load_thruster_requested.connect(func() -> void:
		_emit_file_request("load_thruster", "thrusters", "template.rovthruster.json", {"*.rovthruster.json": "FILE_FILTER_ROV_THRUSTER"}, false)
	)
	thruster_designer_panel.thruster_template_changed.connect(func(payload: Dictionary) -> void: thruster_template_changed.emit(payload))

	chart_workspace.save_chart_layout_requested.connect(func() -> void:
		_emit_file_request("save_chart_layout", "chart_layouts", "layout.rovchart.json", {"*.rovchart.json": "FILE_FILTER_ROV_CHART_LAYOUT"}, true)
	)
	chart_workspace.load_chart_layout_requested.connect(func() -> void:
		_emit_file_request("load_chart_layout", "chart_layouts", "layout.rovchart.json", {"*.rovchart.json": "FILE_FILTER_ROV_CHART_LAYOUT"}, false)
	)


## Emits the stable file-request signal after localizing the visible file filters.
func _emit_file_request(operation: String, category: String, file_name: String, filters_by_pattern: Dictionary, save_mode: bool) -> void:
	request_file_path.emit(operation, category, file_name, _file_filters(filters_by_pattern), save_mode)


## Builds localized file filter labels from `pattern -> translation_key` pairs.
func _file_filters(filter_keys: Dictionary) -> PackedStringArray:
	var filters: PackedStringArray = PackedStringArray()
	for pattern_variant: Variant in filter_keys.keys():
		var pattern: String = str(pattern_variant)
		filters.append("%s ; %s" % [pattern, AppLocalizationScript.translate(str(filter_keys[pattern_variant]))])
	return filters
