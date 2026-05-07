## Controls the right-side live dashboard for the ROV simulator.
## Owns the inspector panel rows that show live simulation and engineering state.
## Mount this script on the `InspectorPanel` PanelContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimDashboardPanel
extends PanelContainer

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

@onready var dashboard_title: Label = get_node("InspectorMargin/InspectorVBox/DashboardTitle") as Label
@onready var depth_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/DepthRow") as LabelValueRow
@onready var velocity_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/VelocityRow") as LabelValueRow
@onready var attitude_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/AttitudeRow") as LabelValueRow
@onready var angular_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/AngularRow") as LabelValueRow
@onready var net_force_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/NetForceRow") as LabelValueRow
@onready var net_torque_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/NetTorqueRow") as LabelValueRow
@onready var v2_dashboard_title: Label = get_node("InspectorMargin/InspectorVBox/V2DashboardTitle") as Label
@onready var current_velocity_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/CurrentVelocityRow") as LabelValueRow
@onready var relative_velocity_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/RelativeVelocityRow") as LabelValueRow
@onready var sensor_depth_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/SensorDepthRow") as LabelValueRow
@onready var sensor_heading_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/SensorHeadingRow") as LabelValueRow
@onready var control_error_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/ControlErrorRow") as LabelValueRow
@onready var task_status_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/TaskStatusRow") as LabelValueRow
@onready var assist_force_row: LabelValueRow = get_node("InspectorMargin/InspectorVBox/AssistForceRow") as LabelValueRow


## Applies localized labels to the live dashboard rows.
## Example:
## `dashboard_panel.apply_static_texts()`
func apply_static_texts() -> void:
	dashboard_title.text = AppLocalizationScript.translate("MAIN_DASHBOARD_TITLE")
	v2_dashboard_title.text = AppLocalizationScript.translate("V2_DASHBOARD_TITLE")
	depth_row.set_label_text(AppLocalizationScript.translate("MAIN_DEPTH"))
	velocity_row.set_label_text(AppLocalizationScript.translate("MAIN_VELOCITY"))
	attitude_row.set_label_text(AppLocalizationScript.translate("MAIN_ATTITUDE"))
	angular_row.set_label_text(AppLocalizationScript.translate("MAIN_ANGULAR_VELOCITY"))
	net_force_row.set_label_text(AppLocalizationScript.translate("FORCE_NET"))
	net_torque_row.set_label_text(AppLocalizationScript.translate("FORCE_NET_TORQUE"))
	current_velocity_row.set_label_text(AppLocalizationScript.translate("CURRENT_VELOCITY"))
	relative_velocity_row.set_label_text(AppLocalizationScript.translate("RELATIVE_VELOCITY"))
	sensor_depth_row.set_label_text(AppLocalizationScript.translate("SENSOR_DEPTH"))
	sensor_heading_row.set_label_text(AppLocalizationScript.translate("SENSOR_HEADING"))
	control_error_row.set_label_text(AppLocalizationScript.translate("CONTROL_ERROR"))
	task_status_row.set_label_text(AppLocalizationScript.translate("TASK_STATUS"))
	assist_force_row.set_label_text(AppLocalizationScript.translate("CONTROL_ASSIST"))


## Updates the dashboard row values using the latest live payload.
## Example:
## `dashboard_panel.set_dashboard(payload)`
func set_dashboard(payload: Dictionary) -> void:
	depth_row.set_value_text(str(payload.get("depth", "")))
	velocity_row.set_value_text(str(payload.get("velocity", "")))
	attitude_row.set_value_text(str(payload.get("attitude", "")))
	angular_row.set_value_text(str(payload.get("angular", "")))
	net_force_row.set_value_text(str(payload.get("net_force", "")))
	net_torque_row.set_value_text(str(payload.get("net_torque", "")))
	current_velocity_row.set_value_text(str(payload.get("current_velocity", "")))
	relative_velocity_row.set_value_text(str(payload.get("relative_velocity", "")))
	sensor_depth_row.set_value_text(str(payload.get("sensor_depth", "")))
	sensor_heading_row.set_value_text(str(payload.get("sensor_heading", "")))
	control_error_row.set_value_text(str(payload.get("control_error", "")))
	task_status_row.set_value_text(str(payload.get("task_status", "")))
	assist_force_row.set_value_text(str(payload.get("assist_force", "")))
