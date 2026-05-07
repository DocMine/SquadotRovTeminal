## ROV 仿真主场景调度脚本，负责连接仿真世界、记录器、相机控制与 `RootControl` UI 聚合层。
## 该脚本属于 `5_rovsim` 页面根层，不直接操作 UI 叶子控件，只通过 `ROVSimRootControl` 的公开接口与信号协作。
class_name ROVSimMain
extends Node

const ROVPresetLibraryScript = preload("res://Levels/5_rovsim/scripts/presets/rov_preset_library.gd")
const AppLocalizationScript = preload("res://modules/ui_modules/0_Core_Autoload/AppLocalization.gd")
const MachineConfigScript = preload("res://Levels/5_rovsim/scripts/model/machine_config.gd")
const ThrusterTemplateScript = preload("res://Levels/5_rovsim/scripts/model/thruster_template.gd")
const ChartLayoutConfigScript = preload("res://Levels/5_rovsim/scripts/model/chart_layout_config.gd")
const MachineSerializerScript = preload("res://Levels/5_rovsim/scripts/io/machine_serializer.gd")
const ThrusterSerializerScript = preload("res://Levels/5_rovsim/scripts/io/thruster_serializer.gd")
const RecordSerializerScript = preload("res://Levels/5_rovsim/scripts/io/record_serializer.gd")
const ChartLayoutSerializerScript = preload("res://Levels/5_rovsim/scripts/io/chart_layout_serializer.gd")
const CsvExporterScript = preload("res://Levels/5_rovsim/scripts/io/csv_exporter.gd")

@onready var rov: ROVController = $World/ROV
@onready var camera: Camera3D = $World/Camera3D
@onready var force_renderer: ForceVectorRenderer = $World/ForceVectorRenderer
@onready var recorder: DataRecorder = $DataRecorder
@onready var root_control: ROVSimRootControl = $UI/RootControl

var _ui_accumulator_s: float = 0.0
var _preset_ids: PackedStringArray = PackedStringArray()
var _pending_file_operation: String = ""
var _machine_path: String = ""
var _frame_path: String = ""
var _thruster_path: String = ""
var _record_path: String = ""
var _chart_layout_path: String = ""
var _record_saved: bool = true
var _active_thruster_template: ThrusterTemplate = ThrusterTemplateScript.new()
var _chart_layout: ChartLayoutConfig = ChartLayoutConfigScript.new()
var _loaded_record_payload: Dictionary = {}
var _last_live_chart_time_s: float = -INF
var _camera_target: Vector3 = Vector3.ZERO
var _camera_yaw_rad: float = 0.0
var _camera_pitch_rad: float = -0.42
var _camera_distance_m: float = 5.55
var _is_orbiting_camera: bool = false
var _is_panning_camera: bool = false
var _selected_thruster_index: int = -1


func _ready() -> void:
	AppLocalizationScript.ensure_ready()
	recorder.set_recording(false)
	_connect_root_control_signals()
	_setup_preset_options()
	_on_environment_changed(root_control.get_environment_inputs())
	_on_control_changed(root_control.get_control_inputs())
	_load_preset("stable")
	root_control.set_thruster_template_values(_active_thruster_template)
	_update_record_button()
	_update_dashboard()
	_update_resource_paths()
	_update_camera_transform()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		root_control.apply_static_texts()
		_setup_preset_options()
		_update_start_button()
		_update_record_button()


func _physics_process(delta: float) -> void:
	recorder.tick(delta, rov.get_data_frame())
	_ui_accumulator_s += delta
	if _ui_accumulator_s >= 0.08:
		_ui_accumulator_s = 0.0
		_update_dashboard()
		if root_control.is_charts_tab_active():
			_update_charts()
		_update_resource_paths()


func _unhandled_input(event: InputEvent) -> void:
	if not root_control.is_3d_simulation_tab_active():
		return
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null:
		if not root_control.is_3d_simulation_pointer_active(mouse_button_event.position):
			return
		_handle_camera_mouse_button(mouse_button_event)
		return
	var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion_event != null:
		if not _is_orbiting_camera and not _is_panning_camera and not root_control.is_3d_simulation_pointer_active(mouse_motion_event.position):
			return
		_handle_camera_mouse_motion(mouse_motion_event)


func _connect_root_control_signals() -> void:
	root_control.connect("start_requested", _on_start_pressed)
	root_control.connect("record_requested", _on_record_pressed)
	root_control.connect("clear_requested", _on_clear_pressed)
	root_control.connect("clear_frame_requested", _on_clear_frame_pressed)
	root_control.connect("request_file_path", _on_request_file_path)
	root_control.connect("add_thruster_requested", _on_add_thruster_pressed)
	root_control.connect("remove_thruster_requested", _on_remove_thruster_pressed)
	root_control.connect("preset_selected", _on_preset_selected)
	root_control.connect("command_changed", _on_command_changed)
	root_control.connect("environment_changed", _on_environment_changed)
	root_control.connect("control_changed", _on_control_changed)
	root_control.connect("machine_parameters_changed", _on_machine_parameter_changed)
	root_control.connect("thruster_template_changed", _on_thruster_template_changed)
	root_control.connect("thruster_selected", _select_thruster)
	root_control.connect("thruster_transform_changed", _on_thruster_transform_changed)
	root_control.connect("file_path_selected", _on_file_path_selected)
	root_control.connect("playback_frame_selected", _on_playback_slider_changed)
	recorder.connect("frame_recorded", _on_frame_recorded)


func _setup_preset_options() -> void:
	_preset_ids = ROVPresetLibraryScript.get_preset_ids()
	var titles: PackedStringArray = PackedStringArray()
	for preset_id: String in _preset_ids:
		titles.append(AppLocalizationScript.translate(ROVPresetLibraryScript.get_preset_title_key(preset_id)))
	root_control.set_preset_options(titles)


func _load_preset(preset_id: String) -> void:
	var was_running: bool = rov.is_running
	rov.set_running(false)
	rov.load_configuration(ROVPresetLibraryScript.get_preset(preset_id))
	rov.apply_template_to_thrusters(_active_thruster_template)
	rov.set_all_thruster_commands(_get_command_value())
	rov.set_running(was_running)
	_frame_path = rov.frame_model_path
	recorder.clear()
	_reset_live_charts()
	_record_saved = true
	_update_machine_parameter_ui()
	_select_thruster(0)
	var preset_title: String = AppLocalizationScript.translate(ROVPresetLibraryScript.get_preset_title_key(preset_id))
	_set_status(AppLocalizationScript.translate("STATUS_LOADED") % preset_title, Color(0.2, 0.55, 0.95))
	_update_start_button()


func _on_start_pressed() -> void:
	rov.set_running(not rov.is_running)
	_update_start_button()


func _on_record_pressed() -> void:
	recorder.set_recording(not recorder.is_recording)
	_update_record_button()


func _on_clear_pressed() -> void:
	recorder.clear()
	_reset_live_charts()
	rov.reset_motion()
	_record_saved = true
	_set_status(AppLocalizationScript.translate("STATUS_CLEARED"), Color(0.45, 0.5, 0.56))


func _on_add_thruster_pressed() -> void:
	rov.add_demo_thruster(_get_command_value())
	rov.apply_template_to_thrusters(_active_thruster_template)
	_select_thruster(rov.get_thruster_editor_rows().size() - 1)
	_set_status(AppLocalizationScript.translate("STATUS_THRUSTER_ADDED"), Color(0.25, 0.62, 0.36))
	_update_dashboard()


func _on_remove_thruster_pressed() -> void:
	rov.remove_last_thruster()
	var rows: Array[Dictionary] = rov.get_thruster_editor_rows()
	_select_thruster(mini(_selected_thruster_index, rows.size() - 1))
	_set_status(AppLocalizationScript.translate("STATUS_THRUSTER_REMOVED"), Color(0.72, 0.52, 0.22))
	_update_dashboard()


func _on_preset_selected(index: int) -> void:
	if index < 0 or index >= _preset_ids.size():
		return
	_load_preset(_preset_ids[index])


func _on_command_changed(value: float) -> void:
	rov.set_all_thruster_commands(value)


func _on_environment_changed(payload: Dictionary) -> void:
	rov.set_environment_parameters(
		int(payload.get("mode", 0)),
		float(payload.get("current_x_mps", 0.0)),
		float(payload.get("current_z_mps", 0.0)),
		float(payload.get("turbulence", 0.0))
	)


func _on_control_changed(payload: Dictionary) -> void:
	rov.set_control_parameters(
		int(payload.get("mode", 0)),
		float(payload.get("target_depth_m", 1.2)),
		float(payload.get("target_heading_deg", 0.0)),
		float(payload.get("target_speed_mps", 0.0))
	)


func _on_machine_parameter_changed(payload: Dictionary) -> void:
	rov.update_machine_parameters(
		float(payload.get("mass_kg", 50.0)),
		float(payload.get("volume_m3", 0.051)),
		float(payload.get("com_y", 0.0)),
		float(payload.get("cob_y", 0.16))
	)


func _on_thruster_template_changed(payload: Dictionary) -> void:
	_active_thruster_template.max_forward_thrust_n = float(payload.get("max_forward_thrust_n", 35.0))
	_active_thruster_template.max_reverse_thrust_n = float(payload.get("max_reverse_thrust_n", 28.0))
	_active_thruster_template.diameter_m = float(payload.get("diameter_m", 0.16))
	_active_thruster_template.length_m = float(payload.get("length_m", 0.24))
	rov.apply_template_to_thrusters(_active_thruster_template)


func _on_frame_recorded(_frame: RefCounted) -> void:
	_record_saved = false


func _on_request_file_path(operation: String, category: String, file_name: String, filters: PackedStringArray, save_mode: bool) -> void:
	_pending_file_operation = operation
	root_control.request_file(operation, _default_path(category, file_name), filters, save_mode)


func _on_file_path_selected(path: String) -> void:
	match _pending_file_operation:
		"save_machine":
			_save_machine(path)
		"load_machine":
			_load_machine(path)
		"import_frame":
			_import_frame(path)
		"save_thruster":
			_save_thruster_template(path)
		"load_thruster":
			_load_thruster_template(path)
		"save_record":
			_save_record(path)
		"load_record":
			_load_record(path)
		"export_csv":
			_export_csv(path)
		"save_chart_layout":
			_save_chart_layout(path)
		"load_chart_layout":
			_load_chart_layout(path)
	_pending_file_operation = ""
	_update_resource_paths()


func _import_frame(path: String) -> void:
	if rov.import_frame_model(path):
		_frame_path = path
		_set_status(AppLocalizationScript.translate("STATUS_FRAME_IMPORTED"), Color(0.25, 0.62, 0.36))
	else:
		_frame_path = path
		_set_status(AppLocalizationScript.translate("STATUS_FRAME_IMPORT_FAILED"), Color(0.75, 0.28, 0.22))
	_update_resource_paths()


func _on_clear_frame_pressed() -> void:
	rov.clear_frame_model()
	_frame_path = ""
	_set_status(AppLocalizationScript.translate("STATUS_FRAME_CLEARED"), Color(0.45, 0.5, 0.56))
	_update_resource_paths()


func _save_machine(path: String) -> void:
	var machine: MachineConfig = MachineConfigScript.new()
	machine.load_dictionary(rov.export_machine_config())
	if MachineSerializerScript.save(path, machine):
		_machine_path = path
		_set_status(AppLocalizationScript.translate("STATUS_MACHINE_SAVED"), Color(0.25, 0.62, 0.36))


func _load_machine(path: String) -> void:
	var machine: MachineConfig = MachineSerializerScript.load(path)
	if machine == null:
		return
	rov.load_configuration(machine.to_runtime_dictionary(_get_command_value()))
	rov.apply_template_to_thrusters(_active_thruster_template)
	_machine_path = path
	_frame_path = machine.frame_model_path
	_update_machine_parameter_ui()
	_select_thruster(0)
	_set_status(AppLocalizationScript.translate("STATUS_MACHINE_LOADED"), Color(0.2, 0.55, 0.95))


func _save_thruster_template(path: String) -> void:
	if ThrusterSerializerScript.save(path, _active_thruster_template):
		_thruster_path = path
		_set_status(AppLocalizationScript.translate("STATUS_THRUSTER_TEMPLATE_SAVED"), Color(0.25, 0.62, 0.36))


func _load_thruster_template(path: String) -> void:
	var thruster_template: ThrusterTemplate = ThrusterSerializerScript.load(path)
	if thruster_template == null:
		return
	_active_thruster_template = thruster_template
	root_control.set_thruster_template_values(_active_thruster_template)
	rov.apply_template_to_thrusters(_active_thruster_template)
	_thruster_path = path
	_set_status(AppLocalizationScript.translate("STATUS_THRUSTER_TEMPLATE_LOADED"), Color(0.2, 0.55, 0.95))


func _save_record(path: String) -> void:
	var frames: Array[RefCounted] = recorder.get_all_frames()
	var machine_summary: Dictionary = rov.export_machine_config()
	if RecordSerializerScript.save(path, frames, recorder.sample_frequency_hz, machine_summary):
		_record_path = path
		_record_saved = true
		_set_status(AppLocalizationScript.translate("STATUS_RECORD_SAVED"), Color(0.25, 0.62, 0.36))


func _load_record(path: String) -> void:
	_loaded_record_payload = RecordSerializerScript.load(path)
	_record_path = path
	var frame_count: int = int(_loaded_record_payload.get("frame_count", 0))
	root_control.set_record_loaded(path, frame_count)
	_update_charts_from_record_payload(_loaded_record_payload)
	_apply_playback_frame(0)
	_set_status(AppLocalizationScript.translate("STATUS_RECORD_LOADED"), Color(0.2, 0.55, 0.95))


func _export_csv(path: String) -> void:
	var frames: Array[RefCounted] = recorder.get_all_frames()
	if CsvExporterScript.export_frames(path, frames):
		_set_status(AppLocalizationScript.translate("STATUS_CSV_EXPORTED"), Color(0.25, 0.62, 0.36))


func _save_chart_layout(path: String) -> void:
	_chart_layout.window_seconds = recorder.window_seconds
	if ChartLayoutSerializerScript.save(path, _chart_layout):
		_chart_layout_path = path
		_set_status(AppLocalizationScript.translate("STATUS_CHART_LAYOUT_SAVED"), Color(0.25, 0.62, 0.36))


func _load_chart_layout(path: String) -> void:
	var chart_layout: ChartLayoutConfig = ChartLayoutSerializerScript.load(path)
	if chart_layout == null:
		return
	_chart_layout = chart_layout
	recorder.window_seconds = _chart_layout.window_seconds
	_chart_layout_path = path
	_set_status(AppLocalizationScript.translate("STATUS_CHART_LAYOUT_LOADED"), Color(0.2, 0.55, 0.95))


func _update_start_button() -> void:
	var running: bool = rov.is_running
	root_control.set_sim_running(running)
	if running:
		_set_status(AppLocalizationScript.translate("STATUS_SIM_RUNNING"), Color(0.25, 0.62, 0.36))
	else:
		_set_status(AppLocalizationScript.translate("STATUS_SIM_PAUSED"), Color(0.45, 0.5, 0.56))


func _update_record_button() -> void:
	root_control.set_recording(recorder.is_recording)


func _handle_camera_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_is_orbiting_camera = event.pressed
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_is_panning_camera = event.pressed
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_camera_distance_m = maxf(1.2, _camera_distance_m * 0.9)
		_update_camera_transform()
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_camera_distance_m = minf(18.0, _camera_distance_m * 1.1)
		_update_camera_transform()
		get_viewport().set_input_as_handled()


func _handle_camera_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_orbiting_camera:
		_camera_yaw_rad -= event.relative.x * 0.006
		_camera_pitch_rad = clampf(_camera_pitch_rad - event.relative.y * 0.006, deg_to_rad(-78.0), deg_to_rad(78.0))
		_update_camera_transform()
		get_viewport().set_input_as_handled()
	elif _is_panning_camera:
		var right: Vector3 = camera.global_transform.basis.x
		var up: Vector3 = camera.global_transform.basis.y
		var pan_scale: float = _camera_distance_m * 0.0015
		_camera_target += (-right * event.relative.x + up * event.relative.y) * pan_scale
		_update_camera_transform()
		get_viewport().set_input_as_handled()


func _update_camera_transform() -> void:
	var offset: Vector3 = Vector3(
		sin(_camera_yaw_rad) * cos(_camera_pitch_rad),
		-sin(_camera_pitch_rad),
		cos(_camera_yaw_rad) * cos(_camera_pitch_rad)
	) * _camera_distance_m
	camera.global_position = _camera_target + offset
	camera.look_at(_camera_target, Vector3.UP)


func _update_dashboard() -> void:
	var state: RefCounted = rov.get_current_state()
	var rotation_quat: Quaternion = state.get("rotation_quat")
	var linear_velocity: Vector3 = state.get("linear_velocity_mps")
	var angular_velocity: Vector3 = state.get("angular_velocity_radps")
	var euler: Vector3 = rotation_quat.get_euler()
	var snapshot: RefCounted = rov.get_force_snapshot()
	var net_force: Vector3 = snapshot.get("net_force_n")
	var net_torque: Vector3 = snapshot.get("net_torque_nm")
	var environment_state: RefCounted = rov.get_environment_state()
	var current_velocity: Vector3 = environment_state.get("current_velocity_mps")
	var relative_velocity: Vector3 = environment_state.get("relative_velocity_mps")
	var sensor_frame: RefCounted = rov.get_sensor_frame()
	var control_state: RefCounted = rov.get_control_state()
	var assist_force: Vector3 = control_state.get("assist_force_n")
	var assist_torque: Vector3 = control_state.get("assist_torque_nm")
	root_control.set_dashboard({
		"depth": "%.2f m" % float(state.get("depth_m")),
		"velocity": "%.2f m/s  (%.2f, %.2f, %.2f)" % [linear_velocity.length(), linear_velocity.x, linear_velocity.y, linear_velocity.z],
		"attitude": "R %.1f deg  P %.1f deg  Y %.1f deg" % [rad_to_deg(euler.z), rad_to_deg(euler.x), rad_to_deg(euler.y)],
		"angular": "%.2f, %.2f, %.2f rad/s" % [angular_velocity.x, angular_velocity.y, angular_velocity.z],
		"net_force": "%.1f N  (%.1f, %.1f, %.1f)" % [net_force.length(), net_force.x, net_force.y, net_force.z],
		"net_torque": "%.1f N*m  (%.1f, %.1f, %.1f)" % [net_torque.length(), net_torque.x, net_torque.y, net_torque.z],
		"current_velocity": "%.2f m/s  (%.2f, %.2f, %.2f)" % [current_velocity.length(), current_velocity.x, current_velocity.y, current_velocity.z],
		"relative_velocity": "%.2f m/s  (%.2f, %.2f, %.2f)" % [relative_velocity.length(), relative_velocity.x, relative_velocity.y, relative_velocity.z],
		"sensor_depth": "%.2f m" % float(sensor_frame.get("depth_m")),
		"sensor_heading": "%.1f deg" % rad_to_deg(float(sensor_frame.get("compass_heading_rad"))),
		"control_error": "D %.2f m  H %.1f deg" % [float(control_state.get("depth_error_m")), rad_to_deg(float(control_state.get("heading_error_rad")))],
		"task_status": AppLocalizationScript.translate(str(control_state.get("task_status_key"))),
		"assist_force": "%.1f N / %.1f N*m" % [assist_force.length(), assist_torque.length()],
	})
	force_renderer.set_snapshot(snapshot)
	_update_report(snapshot)


func _update_thruster_list() -> void:
	var editor_rows: Array[Dictionary] = rov.get_thruster_editor_rows()
	if editor_rows.is_empty():
		_selected_thruster_index = -1
	else:
		_selected_thruster_index = clampi(_selected_thruster_index, 0, editor_rows.size() - 1)
	rov.set_selected_thruster_index(_selected_thruster_index)
	root_control.set_thruster_editor_rows(editor_rows, _selected_thruster_index)


func _select_thruster(index: int) -> void:
	var rows: Array[Dictionary] = rov.get_thruster_editor_rows()
	if rows.is_empty():
		_selected_thruster_index = -1
	else:
		_selected_thruster_index = clampi(index, 0, rows.size() - 1)
	_update_thruster_list()


func _on_thruster_transform_changed(index: int, position_m: Vector3, rotation_rad: Vector3) -> void:
	_selected_thruster_index = index
	rov.update_thruster_transform(index, position_m, rotation_rad)
	_update_thruster_list()
	_update_dashboard()


func _update_charts() -> void:
	var frames: Array[RefCounted] = recorder.get_window_frames_after(_last_live_chart_time_s)
	if frames.is_empty():
		return
	var depth_series: Dictionary = {"depth": []}
	var roll_pitch_yaw: Dictionary = {"roll": [], "pitch": [], "yaw": []}
	var thrust_series: Dictionary = {}
	var speed_series: Dictionary = {"speed": []}
	var force_series: Dictionary = {"net": [], "drag": [], "buoyancy": [], "gravity": []}
	var v2_series: Dictionary = {"current": [], "sensor_depth": [], "depth_error": [], "assist_force": []}
	for frame: RefCounted in frames:
		var frame_state: RefCounted = frame.get("state")
		var t: float = float(frame.get("time_s"))
		var frame_rotation: Quaternion = frame_state.get("rotation_quat")
		var frame_velocity: Vector3 = frame_state.get("linear_velocity_mps")
		var euler: Vector3 = frame_rotation.get_euler()
		depth_series["depth"].append(Vector2(t, float(frame_state.get("depth_m"))))
		roll_pitch_yaw["roll"].append(Vector2(t, rad_to_deg(euler.z)))
		roll_pitch_yaw["pitch"].append(Vector2(t, rad_to_deg(euler.x)))
		roll_pitch_yaw["yaw"].append(Vector2(t, rad_to_deg(euler.y)))
		speed_series["speed"].append(Vector2(t, frame_velocity.length()))
		force_series["net"].append(Vector2(t, frame.get("force_snapshot").get("net_force_n").length()))
		var environment_state: RefCounted = frame.get("environment_state")
		v2_series["current"].append(Vector2(t, Vector3(environment_state.get("current_velocity_mps")).length()))
		var sensor_frame: RefCounted = frame.get("sensor_frame")
		v2_series["sensor_depth"].append(Vector2(t, float(sensor_frame.get("depth_m"))))
		var control_state: RefCounted = frame.get("control_state")
		v2_series["depth_error"].append(Vector2(t, float(control_state.get("depth_error_m"))))
		v2_series["assist_force"].append(Vector2(t, Vector3(control_state.get("assist_force_n")).length()))
		_append_force_type_series(force_series, frame.get("force_snapshot"), t)
		var frame_thrusters: Array[RefCounted] = frame.get("thrusters")
		for thruster: RefCounted in frame_thrusters:
			var display_name: String = str(thruster.get("display_name"))
			if not thrust_series.has(display_name):
				thrust_series[display_name] = []
			thrust_series[display_name].append(Vector2(t, float(thruster.get("thrust_n"))))
		_last_live_chart_time_s = t
	root_control.set_chart_series({
		"depth": depth_series,
		"attitude": roll_pitch_yaw,
		"thrust": thrust_series,
		"speed": speed_series,
		"force": force_series,
		"v2": v2_series,
	})


func _append_force_type_series(force_series: Dictionary, snapshot: RefCounted, time_s: float) -> void:
	var totals: Dictionary = {"drag": 0.0, "buoyancy": 0.0, "gravity": 0.0}
	var samples: Array[RefCounted] = snapshot.get("samples")
	for sample: RefCounted in samples:
		var force_type: String = str(sample.get("force_type"))
		if totals.has(force_type):
			totals[force_type] = float(totals[force_type]) + Vector3(sample.get("vector_n")).length()
	for key: String in totals.keys():
		force_series[key].append(Vector2(time_s, float(totals[key])))


func _update_charts_from_record_payload(payload: Dictionary) -> void:
	_reset_live_charts(false)
	var frames: Array = payload.get("frames", [])
	var depth_series: Dictionary = {"depth": []}
	var speed_series: Dictionary = {"speed": []}
	var force_series: Dictionary = {"net": []}
	var v2_series: Dictionary = {"current": [], "sensor_depth": [], "depth_error": [], "assist_force": []}
	for row_variant: Variant in frames:
		var row: Dictionary = row_variant
		var state: Dictionary = row.get("state", {})
		var t: float = float(row.get("time_s", 0.0))
		depth_series["depth"].append(Vector2(t, float(state.get("depth_m", 0.0))))
		var velocity: Array = state.get("linear_velocity_mps", [0.0, 0.0, 0.0])
		speed_series["speed"].append(Vector2(t, Vector3(float(velocity[0]), float(velocity[1]), float(velocity[2])).length()))
		var force_snapshot: Dictionary = row.get("force_snapshot", {})
		var net_force: Array = force_snapshot.get("net_force_n", [0.0, 0.0, 0.0])
		force_series["net"].append(Vector2(t, Vector3(float(net_force[0]), float(net_force[1]), float(net_force[2])).length()))
		var environment_state: Dictionary = row.get("environment_state", {})
		var current_velocity: Array = environment_state.get("current_velocity_mps", [0.0, 0.0, 0.0])
		v2_series["current"].append(Vector2(t, Vector3(float(current_velocity[0]), float(current_velocity[1]), float(current_velocity[2])).length()))
		var sensor_frame: Dictionary = row.get("sensor_frame", {})
		v2_series["sensor_depth"].append(Vector2(t, float(sensor_frame.get("depth_m", 0.0))))
		var control_state: Dictionary = row.get("control_state", {})
		v2_series["depth_error"].append(Vector2(t, float(control_state.get("depth_error_m", 0.0))))
		var assist_force: Array = control_state.get("assist_force_n", [0.0, 0.0, 0.0])
		v2_series["assist_force"].append(Vector2(t, Vector3(float(assist_force[0]), float(assist_force[1]), float(assist_force[2])).length()))
	root_control.set_chart_series({
		"depth": depth_series,
		"speed": speed_series,
		"force": force_series,
		"v2": v2_series,
	})


func _on_playback_slider_changed(index: int) -> void:
	_apply_playback_frame(index)


func _apply_playback_frame(index: int) -> void:
	var frames: Array = _loaded_record_payload.get("frames", [])
	if frames.is_empty():
		root_control.set_empty_playback_frame()
		return
	var clamped_index: int = clampi(index, 0, frames.size() - 1)
	var frame: Dictionary = frames[clamped_index]
	rov.set_running(false)
	rov.apply_record_frame(frame)
	var state: Dictionary = frame.get("state", {})
	root_control.set_playback_frame(clamped_index, frames.size(), float(state.get("depth_m", 0.0)))
	force_renderer.set_snapshot(rov.get_force_snapshot())
	_update_dashboard()


func _update_machine_parameter_ui() -> void:
	root_control.set_machine_parameter_values(rov.export_machine_config())


func _update_report(snapshot: RefCounted) -> void:
	var machine: Dictionary = rov.export_machine_config()
	var center_of_mass: Vector3 = machine.get("center_of_mass_m", Vector3.ZERO)
	var center_of_buoyancy: Vector3 = machine.get("center_of_buoyancy_m", Vector3.ZERO)
	var net_torque: Vector3 = snapshot.get("net_torque_nm")
	var lines: PackedStringArray = PackedStringArray()
	if center_of_buoyancy.y <= center_of_mass.y:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_COB"))
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_COB"))
	if net_torque.length() > 50.0:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_TORQUE"))
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_TORQUE"))
	var symmetry_score: float = _calculate_thruster_symmetry_score(machine.get("thrusters", []))
	if symmetry_score > 0.18:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_SYMMETRY") % symmetry_score)
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_SYMMETRY") % symmetry_score)
	var vertical_score: float = _calculate_vertical_authority_score(machine.get("thrusters", []))
	if vertical_score < 0.35:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_VERTICAL_AUTHORITY") % vertical_score)
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_VERTICAL_AUTHORITY") % vertical_score)
	var environment_state: RefCounted = rov.get_environment_state()
	var current_velocity: Vector3 = environment_state.get("current_velocity_mps")
	if current_velocity.length() > 0.45:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_CURRENT") % current_velocity.length())
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_CURRENT"))
	var control_state: RefCounted = rov.get_control_state()
	var depth_error: float = absf(float(control_state.get("depth_error_m")))
	var heading_error_deg: float = absf(rad_to_deg(float(control_state.get("heading_error_rad"))))
	if int(control_state.get("mode")) > 0 and (depth_error > 0.5 or heading_error_deg > 18.0):
		lines.append(AppLocalizationScript.translate("REPORT_WARN_CONTROL") % [depth_error, heading_error_deg])
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_CONTROL"))
	var saturation: float = float(control_state.get("saturated_thruster_ratio"))
	if saturation > 0.25:
		lines.append(AppLocalizationScript.translate("REPORT_WARN_SATURATION") % (saturation * 100.0))
	else:
		lines.append(AppLocalizationScript.translate("REPORT_PASS_SATURATION"))
	root_control.set_report_lines(lines)


func _update_resource_paths() -> void:
	var record_saved_text: String = AppLocalizationScript.translate("STATUS_SAVED")
	if not _record_saved:
		record_saved_text = AppLocalizationScript.translate("STATUS_UNSAVED")
	root_control.set_resource_paths({
		"project_path": ProjectSettings.globalize_path("user://rovsim/"),
		"machine_path": _path_or_placeholder(_machine_path),
		"frame_path": _path_or_placeholder(_frame_path),
		"thruster_path": _path_or_placeholder(_thruster_path),
		"record_path": _path_or_placeholder(_record_path),
		"chart_path": _path_or_placeholder(_chart_layout_path),
		"sample_rate": "%.1f Hz" % recorder.sample_frequency_hz,
		"frame_count": "%d" % recorder.get_all_frame_count(),
		"record_saved": record_saved_text,
	})


func _reset_live_charts(clear_display: bool = true) -> void:
	_last_live_chart_time_s = -INF
	if clear_display:
		root_control.reset_chart_series()


func _get_command_value() -> float:
	return root_control.get_command_value()


func _set_status(text_value: String, color_value: Color) -> void:
	root_control.set_status(text_value, color_value)


func _default_path(category: String, file_name: String) -> String:
	return ProjectSettings.globalize_path("user://rovsim/%s/%s" % [category, file_name])


func _path_or_placeholder(path: String) -> String:
	if path.is_empty():
		return AppLocalizationScript.translate("RESOURCE_NOT_SAVED")
	return path


func _calculate_thruster_symmetry_score(thrusters: Array) -> float:
	if thrusters.is_empty():
		return 1.0
	var center: Vector3 = Vector3.ZERO
	for row_variant: Variant in thrusters:
		var row: Dictionary = row_variant
		center += row.get("position_m", Vector3.ZERO)
	center /= float(thrusters.size())
	return Vector2(center.x, center.z).length()


func _calculate_vertical_authority_score(thrusters: Array) -> float:
	if thrusters.is_empty():
		return 0.0
	var vertical_sum: float = 0.0
	var total_sum: float = 0.0
	for row_variant: Variant in thrusters:
		var row: Dictionary = row_variant
		var rotation: Vector3 = row.get("rotation_rad", Vector3.ZERO)
		var local_axis: Vector3 = row.get("local_force_axis", Vector3(0.0, 0.0, -1.0))
		var direction: Vector3 = Basis.from_euler(rotation) * local_axis.normalized()
		var max_thrust: float = maxf(1.0, float(row.get("max_thrust_n", 1.0)))
		vertical_sum += absf(direction.y) * max_thrust
		total_sum += max_thrust
	return vertical_sum / maxf(1.0, total_sum)
