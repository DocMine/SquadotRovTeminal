## Controls the chart workbench page for the ROV simulator.
## Owns the save/load chart layout actions and the six realtime chart widgets.
## Mount this script on the `ChartsTab` Control in `scenes/main/main.tscn`.
@tool
class_name ROVSimChartWorkspace
extends Control

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

signal save_chart_layout_requested
signal load_chart_layout_requested

@onready var save_chart_layout_button: Button = get_node("ChartActionRow/SaveChartLayoutButton") as Button
@onready var load_chart_layout_button: Button = get_node("ChartActionRow/LoadChartLayoutButton") as Button
@onready var depth_chart: TauRealtimeChart = get_node("ChartsGrid/DepthChart") as TauRealtimeChart
@onready var attitude_chart: TauRealtimeChart = get_node("ChartsGrid/AttitudeChart") as TauRealtimeChart
@onready var thrust_chart: TauRealtimeChart = get_node("ChartsGrid/ThrustChart") as TauRealtimeChart
@onready var speed_chart: TauRealtimeChart = get_node("ChartsGrid/SpeedChart") as TauRealtimeChart
@onready var force_chart: TauRealtimeChart = get_node("ChartsGrid/ForceChart") as TauRealtimeChart
@onready var v2_chart: TauRealtimeChart = get_node("ChartsGrid/V2Chart") as TauRealtimeChart


## Connects chart action buttons and applies the current localized texts.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	if not save_chart_layout_button.pressed.is_connected(_on_save_chart_layout_button_pressed):
		save_chart_layout_button.pressed.connect(_on_save_chart_layout_button_pressed)
	if not load_chart_layout_button.pressed.is_connected(_on_load_chart_layout_button_pressed):
		load_chart_layout_button.pressed.connect(_on_load_chart_layout_button_pressed)
	apply_static_texts()


## Refreshes the static button texts used by the chart workspace.
## Example:
## `chart_workspace.apply_static_texts()`
func apply_static_texts() -> void:
	save_chart_layout_button.text = AppLocalizationScript.translate("WORKBENCH_SAVE_CHARTS")
	load_chart_layout_button.text = AppLocalizationScript.translate("WORKBENCH_LOAD_CHARTS")


## Pushes the latest series payload into the six realtime charts.
## Example:
## `chart_workspace.set_chart_series(series_payload)`
func set_chart_series(payload: Dictionary) -> void:
	depth_chart.set_series(payload.get("depth", {}))
	attitude_chart.set_series(payload.get("attitude", {}))
	thrust_chart.set_series(payload.get("thrust", {}))
	speed_chart.set_series(payload.get("speed", {}))
	force_chart.set_series(payload.get("force", {}))
	v2_chart.set_series(payload.get("v2", {}))


## Clears all six realtime charts.
## Example:
## `chart_workspace.reset_chart_series()`
func reset_chart_series() -> void:
	set_chart_series({})


## Emits the save-chart-layout business action.
func _on_save_chart_layout_button_pressed() -> void:
	save_chart_layout_requested.emit()


## Emits the load-chart-layout business action.
func _on_load_chart_layout_button_pressed() -> void:
	load_chart_layout_requested.emit()
