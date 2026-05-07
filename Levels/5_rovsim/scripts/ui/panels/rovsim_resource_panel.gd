## Controls the resource, playback, report, and file dialog area for the ROV simulator.
## Owns the left-side resource panel and its file dialog workflow.
## Mount this script on the `ResourcePanel` PanelContainer in `scenes/main/main.tscn`.
@tool
class_name ROVSimResourcePanel
extends PanelContainer

const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")

signal save_record_requested
signal load_record_requested
signal export_csv_requested
signal file_path_selected(path: String)
signal playback_frame_selected(index: int)

@onready var resource_title: Label = get_node("ResourceMargin/ResourceVBox/ResourceTitle") as Label
@onready var project_path_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/ProjectPathRow") as LabelValueRow
@onready var machine_path_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/MachinePathRow") as LabelValueRow
@onready var thruster_path_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/ThrusterPathRow") as LabelValueRow
@onready var record_path_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/RecordPathRow") as LabelValueRow
@onready var chart_path_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/ChartPathRow") as LabelValueRow
@onready var sample_rate_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/SampleRateRow") as LabelValueRow
@onready var frame_count_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/FrameCountRow") as LabelValueRow
@onready var record_saved_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/RecordSavedRow") as LabelValueRow
@onready var save_record_button: Button = get_node("ResourceMargin/ResourceVBox/RecordActionRow/SaveRecordButton") as Button
@onready var load_record_button: Button = get_node("ResourceMargin/ResourceVBox/RecordActionRow/LoadRecordButton") as Button
@onready var export_csv_button: Button = get_node("ResourceMargin/ResourceVBox/RecordActionRow/ExportCsvButton") as Button
@onready var playback_title: Label = get_node("ResourceMargin/ResourceVBox/PlaybackTitle") as Label
@onready var playback_slider: HSlider = get_node("ResourceMargin/ResourceVBox/PlaybackSlider") as HSlider
@onready var playback_frame_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/PlaybackFrameRow") as LabelValueRow
@onready var playback_depth_row: LabelValueRow = get_node("ResourceMargin/ResourceVBox/PlaybackDepthRow") as LabelValueRow
@onready var playback_info: RichTextLabel = get_node("ResourceMargin/ResourceVBox/PlaybackInfo") as RichTextLabel
@onready var report_title: Label = get_node("ResourceMargin/ResourceVBox/ReportTitle") as Label
@onready var report_text: RichTextLabel = get_node("ResourceMargin/ResourceVBox/ReportText") as RichTextLabel
@onready var file_dialog_panel: FileDialogPanel = get_node("ResourceMargin/ResourceVBox/FileDialogPanel") as FileDialogPanel

var _loaded_record_path: String = ""
var _loaded_frame_count: int = 0
var _has_loaded_record: bool = false


## Connects the resource panel buttons and file dialog signals, then applies the localized texts.
func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	if not save_record_button.pressed.is_connected(_on_save_record_button_pressed):
		save_record_button.pressed.connect(_on_save_record_button_pressed)
	if not load_record_button.pressed.is_connected(_on_load_record_button_pressed):
		load_record_button.pressed.connect(_on_load_record_button_pressed)
	if not export_csv_button.pressed.is_connected(_on_export_csv_button_pressed):
		export_csv_button.pressed.connect(_on_export_csv_button_pressed)
	if not file_dialog_panel.save_requested.is_connected(_on_file_dialog_save_requested):
		file_dialog_panel.save_requested.connect(_on_file_dialog_save_requested)
	if not file_dialog_panel.load_requested.is_connected(_on_file_dialog_load_requested):
		file_dialog_panel.load_requested.connect(_on_file_dialog_load_requested)
	if not playback_slider.value_changed.is_connected(_on_playback_slider_value_changed):
		playback_slider.value_changed.connect(_on_playback_slider_value_changed)
	apply_static_texts()
	set_empty_playback_frame()


## Refreshes all static labels in the resource panel for the current locale.
## Example:
## `resource_panel.apply_static_texts()`
func apply_static_texts() -> void:
	resource_title.text = AppLocalizationScript.translate("WORKBENCH_RESOURCE_TITLE")
	playback_title.text = AppLocalizationScript.translate("PLAYBACK_TITLE")
	report_title.text = AppLocalizationScript.translate("REPORT_TITLE")
	save_record_button.text = AppLocalizationScript.translate("WORKBENCH_SAVE_RECORD")
	load_record_button.text = AppLocalizationScript.translate("WORKBENCH_LOAD_RECORD")
	export_csv_button.text = AppLocalizationScript.translate("WORKBENCH_EXPORT_CSV")
	project_path_row.set_label_text(AppLocalizationScript.translate("RESOURCE_PROJECT_PATH"))
	machine_path_row.set_label_text(AppLocalizationScript.translate("RESOURCE_MACHINE_PATH"))
	thruster_path_row.set_label_text(AppLocalizationScript.translate("RESOURCE_THRUSTER_PATH"))
	record_path_row.set_label_text(AppLocalizationScript.translate("RESOURCE_RECORD_PATH"))
	chart_path_row.set_label_text(AppLocalizationScript.translate("RESOURCE_CHART_PATH"))
	sample_rate_row.set_label_text(AppLocalizationScript.translate("RECORD_SAMPLE_RATE"))
	frame_count_row.set_label_text(AppLocalizationScript.translate("RECORD_FRAME_COUNT"))
	record_saved_row.set_label_text(AppLocalizationScript.translate("RECORD_SAVE_STATE"))
	playback_frame_row.set_label_text(AppLocalizationScript.translate("PLAYBACK_FRAME"))
	playback_depth_row.set_label_text(AppLocalizationScript.translate("MAIN_DEPTH"))
	if _has_loaded_record:
		playback_info.text = AppLocalizationScript.translate("PLAYBACK_LOADED_FORMAT") % [_loaded_record_path, _loaded_frame_count]
	else:
		playback_info.text = AppLocalizationScript.translate("PLAYBACK_INFO").replace("\\n", "\n")


## Opens the shared file dialog with the requested defaults.
## Example:
## `resource_panel.request_file("C:/temp/session.json", filters, true)`
func request_file(default_path: String, filters: PackedStringArray, save_mode: bool) -> void:
	file_dialog_panel.set_filters(filters)
	file_dialog_panel.set_full_path(default_path)
	if save_mode:
		file_dialog_panel.request_save_path()
	else:
		file_dialog_panel.request_load_path()


## Updates the panel rows that display current resource paths and record metadata.
## Example:
## `resource_panel.set_resource_paths(payload)`
func set_resource_paths(payload: Dictionary) -> void:
	project_path_row.set_value_text(str(payload.get("project_path", "")))
	machine_path_row.set_value_text(str(payload.get("machine_path", "")))
	thruster_path_row.set_value_text(str(payload.get("thruster_path", "")))
	record_path_row.set_value_text(str(payload.get("record_path", "")))
	chart_path_row.set_value_text(str(payload.get("chart_path", "")))
	sample_rate_row.set_value_text(str(payload.get("sample_rate", "")))
	frame_count_row.set_value_text(str(payload.get("frame_count", "")))
	record_saved_row.set_value_text(str(payload.get("record_saved", "")))


## Shows the playback summary for a loaded record payload.
## Example:
## `resource_panel.set_record_loaded(path, frame_count)`
func set_record_loaded(path: String, frame_count: int) -> void:
	_loaded_record_path = path
	_loaded_frame_count = frame_count
	_has_loaded_record = true
	playback_slider.max_value = maxf(0.0, float(frame_count - 1))
	playback_slider.value = 0.0
	playback_info.text = AppLocalizationScript.translate("PLAYBACK_LOADED_FORMAT") % [path, frame_count]


## Updates the currently selected playback frame summary.
## Example:
## `resource_panel.set_playback_frame(3, 20, 1.45)`
func set_playback_frame(index: int, total: int, depth_m: float) -> void:
	playback_frame_row.set_value_text("%d / %d" % [index + 1, total])
	playback_depth_row.set_value_text("%.2f m" % depth_m)


## Clears the playback frame summary when no record is selected.
## Example:
## `resource_panel.set_empty_playback_frame()`
func set_empty_playback_frame() -> void:
	playback_frame_row.set_value_text("0 / 0")
	playback_depth_row.set_value_text("-")


## Updates the report area using the already localized report lines.
## Example:
## `resource_panel.set_report_lines(PackedStringArray(["Line A", "Line B"]))`
func set_report_lines(lines: PackedStringArray) -> void:
	report_text.text = "\n".join(lines)


## Emits the save-record request for the main coordinator.
func _on_save_record_button_pressed() -> void:
	save_record_requested.emit()


## Emits the load-record request for the main coordinator.
func _on_load_record_button_pressed() -> void:
	load_record_requested.emit()


## Emits the CSV-export request for the main coordinator.
func _on_export_csv_button_pressed() -> void:
	export_csv_requested.emit()


## Forwards the chosen save path from the shared file dialog.
func _on_file_dialog_save_requested(path: String) -> void:
	file_path_selected.emit(path)


## Forwards the chosen load path from the shared file dialog.
func _on_file_dialog_load_requested(path: String) -> void:
	file_path_selected.emit(path)


## Emits the playback frame index selected by the user.
func _on_playback_slider_value_changed(value: float) -> void:
	playback_frame_selected.emit(int(value))
