## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ROVController
extends Node3D

const ROVThrusterScene = preload("res://Levels/5_rovsim/scenes/rov/thruster.tscn")
const ROVStateScript = preload("res://Levels/5_rovsim/scripts/sim/rov_state.gd")
const DataFrameScript = preload("res://Levels/5_rovsim/scripts/data/data_frame.gd")
const ForceSnapshotScript = preload("res://Levels/5_rovsim/scripts/sim/force_snapshot.gd")
const ForceSampleScript = preload("res://Levels/5_rovsim/scripts/sim/force_sample.gd")
const ThrusterTemplateScript = preload("res://Levels/5_rovsim/scripts/model/thruster_template.gd")
const EnvironmentStateScript = preload("res://Levels/5_rovsim/scripts/sim/environment_state.gd")
const SensorFrameScript = preload("res://Levels/5_rovsim/scripts/sensors/sensor_frame.gd")
const SensorSuiteScript = preload("res://Levels/5_rovsim/scripts/sensors/sensor_suite.gd")
const ControlStateScript = preload("res://Levels/5_rovsim/scripts/control/control_state.gd")

@export var body_path: NodePath = NodePath("ROVBody")
@export var thrusters_path: NodePath = NodePath("ROVBody/Thrusters")
@export var imported_frame_root_path: NodePath = NodePath("ROVBody/ImportedFrameRoot")
@export var mass_kg: float = 50.0
@export var displaced_volume_m3: float = 0.051
@export var fluid_density_kg_m3: float = 1000.0
@export var gravity_mps2: float = 9.81
@export var drag_coefficients: Vector3 = Vector3(42.0, 58.0, 46.0)
@export var linear_drag_coefficients: Vector3 = Vector3(8.0, 10.0, 8.0)
@export var angular_drag: Vector3 = Vector3(3.2, 3.6, 3.2)
@export var center_of_mass_m: Vector3 = Vector3.ZERO
@export var center_of_buoyancy_m: Vector3 = Vector3(0.0, 0.16, 0.0)
@export var current_mode: int = 0
@export var base_current_velocity_mps: Vector3 = Vector3.ZERO
@export var layered_current_gradient_mps_per_m: Vector3 = Vector3(0.025, 0.0, -0.015)
@export var turbulence_strength: float = 0.0
@export var control_mode: int = 0
@export var target_depth_m: float = 1.2
@export var target_heading_rad: float = 0.0
@export var target_speed_mps: float = 0.0

var simulation_time_s: float = 0.0
var is_running: bool = false

var _body: RigidBody3D
var _thrusters_root: Node3D
var _imported_frame_root: Node3D
var frame_model_path: String = ""
var _last_drag_force_n: Vector3 = Vector3.ZERO
var _last_buoyancy_force_n: Vector3 = Vector3.ZERO
var _last_gravity_force_n: Vector3 = Vector3.ZERO
var _last_force_snapshot: RefCounted = ForceSnapshotScript.new()
var _last_environment_state: RefCounted = EnvironmentStateScript.new()
var _last_sensor_frame: RefCounted = SensorFrameScript.new()
var _last_control_state: RefCounted = ControlStateScript.new()
var _current_frame_samples: Array[RefCounted] = []


func _ready() -> void:
	_body = get_node(body_path) as RigidBody3D
	_thrusters_root = get_node(thrusters_path) as Node3D
	_imported_frame_root = get_node(imported_frame_root_path) as Node3D
	_apply_body_parameters()
	_refresh_environment_state()
	_refresh_control_state(Vector3.ZERO, Vector3.ZERO)
	_refresh_sensor_frame()
	set_running(false)


func _physics_process(delta: float) -> void:
	if not is_running:
		return
	simulation_time_s += delta
	_current_frame_samples.clear()
	_refresh_environment_state()
	_apply_control_system(delta)
	_apply_hydrodynamics()
	_apply_thruster_forces()
	_refresh_sensor_frame()
	_build_force_snapshot()


func set_running(value: bool) -> void:
	is_running = value
	if _body != null:
		_body.freeze = not value


func reset_motion() -> void:
	simulation_time_s = 0.0
	_body.freeze = true
	_body.linear_velocity = Vector3.ZERO
	_body.angular_velocity = Vector3.ZERO
	_body.global_position = Vector3(0.0, -1.2, 0.0)
	_body.global_rotation = Vector3.ZERO
	_body.freeze = not is_running


func update_machine_parameters(new_mass_kg: float, new_volume_m3: float, new_center_of_mass_y: float, new_center_of_buoyancy_y: float) -> void:
	mass_kg = maxf(1.0, new_mass_kg)
	displaced_volume_m3 = maxf(0.001, new_volume_m3)
	center_of_mass_m.y = new_center_of_mass_y
	center_of_buoyancy_m.y = new_center_of_buoyancy_y
	_apply_body_parameters()


func load_configuration(config: Dictionary) -> void:
	mass_kg = float(config.get("mass_kg", mass_kg))
	displaced_volume_m3 = float(config.get("displaced_volume_m3", displaced_volume_m3))
	drag_coefficients = config.get("drag_coefficients", drag_coefficients)
	linear_drag_coefficients = config.get("linear_drag_coefficients", linear_drag_coefficients)
	angular_drag = config.get("angular_drag", angular_drag)
	center_of_mass_m = config.get("center_of_mass_m", center_of_mass_m)
	center_of_buoyancy_m = config.get("center_of_buoyancy_m", center_of_buoyancy_m)
	frame_model_path = str(config.get("frame_model_path", frame_model_path))
	_apply_body_parameters()
	_clear_thrusters()
	var thruster_configs: Array = config.get("thrusters", [])
	var index: int = 1
	for thruster_config: Dictionary in thruster_configs:
		_create_thruster(index, thruster_config)
		index += 1
	_clear_frame_model()
	if not frame_model_path.is_empty():
		import_frame_model(frame_model_path)
	reset_motion()
	_refresh_environment_state()
	_refresh_control_state(Vector3.ZERO, Vector3.ZERO)
	_refresh_sensor_frame()


func set_environment_parameters(mode: int, current_x_mps: float, current_z_mps: float, turbulence: float) -> void:
	current_mode = mode
	base_current_velocity_mps.x = current_x_mps
	base_current_velocity_mps.z = current_z_mps
	turbulence_strength = maxf(0.0, turbulence)
	_refresh_environment_state()


func set_control_parameters(mode: int, depth_m: float, heading_deg: float, speed_mps: float) -> void:
	control_mode = mode
	target_depth_m = maxf(0.0, depth_m)
	target_heading_rad = deg_to_rad(heading_deg)
	target_speed_mps = maxf(0.0, speed_mps)
	_refresh_control_state(Vector3.ZERO, Vector3.ZERO)


func set_all_thruster_commands(command_value: float) -> void:
	for child: Node in _thrusters_root.get_children():
		if child.has_method("set_command"):
			child.call("set_command", command_value)


func apply_template_to_thrusters(thruster_template: RefCounted) -> void:
	for child: Node in _thrusters_root.get_children():
		if child.has_method("apply_template"):
			child.call("apply_template", thruster_template)
			child.call("set_command", float(child.get("command")))


func add_demo_thruster(command_value: float) -> void:
	var next_index: int = _thrusters_root.get_child_count() + 1
	var side: float = -1.0
	if next_index % 2 == 0:
		side = 1.0
	var row: float = -0.38
	if next_index <= 2:
		row = 0.38
	var config: Dictionary = {
		"name": "Thruster_Custom_%d" % next_index,
		"label": "T%d" % next_index,
		"position_m": Vector3(side * 0.58, 0.0, row),
		"rotation_rad": Vector3.ZERO,
		"max_thrust_n": 34.0,
		"local_force_axis": Vector3(0.0, 0.0, -1.0),
		"command": command_value,
	}
	_create_thruster(next_index, config)


func remove_last_thruster() -> void:
	var count: int = _thrusters_root.get_child_count()
	if count <= 0:
		return
	var child: Node = _thrusters_root.get_child(count - 1)
	child.queue_free()


func get_thruster_editor_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index: int in range(_thrusters_root.get_child_count()):
		var child: Node = _thrusters_root.get_child(index)
		var thruster_node: Node3D = child as Node3D
		if thruster_node == null:
			continue
		var force_direction: Vector3 = thruster_node.global_transform.basis * Vector3(child.get("local_force_axis")).normalized()
		rows.append({
			"index": index,
			"name": child.name,
			"display_name": str(child.get("display_name")),
			"position_m": thruster_node.position,
			"rotation_rad": thruster_node.rotation,
			"force_direction": force_direction,
			"max_thrust_n": float(child.get("max_thrust_n")),
		})
	return rows


func update_thruster_transform(index: int, position_m: Vector3, rotation_rad: Vector3) -> void:
	var thruster_node: Node3D = _get_thruster_node(index)
	if thruster_node == null:
		return
	thruster_node.position = position_m
	thruster_node.rotation = rotation_rad


func set_selected_thruster_index(index: int) -> void:
	for child_index: int in range(_thrusters_root.get_child_count()):
		var child: Node = _thrusters_root.get_child(child_index)
		if child.has_method("set_selected"):
			child.call("set_selected", child_index == index)


func import_frame_model(path: String) -> bool:
	if _imported_frame_root == null:
		return false
	_clear_frame_model()
	frame_model_path = path
	var extension: String = path.get_extension().to_lower()
	if extension == "glb" or extension == "gltf":
		return _import_gltf_frame(path)
	var loaded_resource: Resource = ResourceLoader.load(path)
	if loaded_resource is Mesh:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = loaded_resource as Mesh
		_imported_frame_root.add_child(mesh_instance)
		return true
	if loaded_resource is PackedScene:
		var scene_root: Node = (loaded_resource as PackedScene).instantiate()
		_imported_frame_root.add_child(scene_root)
		return true
	return false


func clear_frame_model() -> void:
	frame_model_path = ""
	_clear_frame_model()


func get_current_state() -> RefCounted:
	var state: RefCounted = ROVStateScript.new()
	state.time_s = simulation_time_s
	state.position_m = _body.global_position
	state.linear_velocity_mps = _body.linear_velocity
	state.rotation_quat = _body.global_transform.basis.get_rotation_quaternion()
	state.angular_velocity_radps = _body.angular_velocity
	state.depth_m = maxf(0.0, -_body.global_position.y)
	return state


func get_thruster_states() -> Array[RefCounted]:
	var states: Array[RefCounted] = []
	for child: Node in _thrusters_root.get_children():
		if child.has_method("get_state"):
			states.append(child.call("get_state"))
	return states


func get_data_frame() -> RefCounted:
	var frame: RefCounted = DataFrameScript.new()
	frame.time_s = simulation_time_s
	frame.state = get_current_state()
	frame.thrusters = get_thruster_states()
	frame.force_snapshot = get_force_snapshot()
	frame.environment_state = get_environment_state()
	frame.sensor_frame = get_sensor_frame()
	frame.control_state = get_control_state()
	return frame


func get_force_snapshot() -> RefCounted:
	return _last_force_snapshot.call("duplicate_snapshot")


func get_environment_state() -> RefCounted:
	return _last_environment_state.call("duplicate_state")


func get_sensor_frame() -> RefCounted:
	return _last_sensor_frame.call("duplicate_frame")


func get_control_state() -> RefCounted:
	return _last_control_state.call("duplicate_state")


func apply_record_frame(frame_data: Dictionary) -> void:
	var state: Dictionary = frame_data.get("state", {})
	var position: Vector3 = _array_to_vector(state.get("position_m", [0.0, -1.2, 0.0]))
	var velocity: Vector3 = _array_to_vector(state.get("linear_velocity_mps", [0.0, 0.0, 0.0]))
	var angular_velocity: Vector3 = _array_to_vector(state.get("angular_velocity_radps", [0.0, 0.0, 0.0]))
	var rotation_values: Array = state.get("rotation_quat", [0.0, 0.0, 0.0, 1.0])
	var rotation_quat: Quaternion = Quaternion(float(rotation_values[0]), float(rotation_values[1]), float(rotation_values[2]), float(rotation_values[3]))
	_body.global_position = position
	_body.global_transform.basis = Basis(rotation_quat)
	_body.linear_velocity = velocity
	_body.angular_velocity = angular_velocity
	simulation_time_s = float(frame_data.get("time_s", simulation_time_s))
	var snapshot: RefCounted = ForceSnapshotScript.new()
	snapshot.call("load_dictionary", frame_data.get("force_snapshot", {}))
	_last_force_snapshot = snapshot
	var environment_state: RefCounted = EnvironmentStateScript.new()
	environment_state.call("load_dictionary", frame_data.get("environment_state", {}))
	_last_environment_state = environment_state
	var sensor_frame: RefCounted = SensorFrameScript.new()
	sensor_frame.call("load_dictionary", frame_data.get("sensor_frame", {}))
	_last_sensor_frame = sensor_frame
	var control_state: RefCounted = ControlStateScript.new()
	control_state.call("load_dictionary", frame_data.get("control_state", {}))
	_last_control_state = control_state


func get_last_drag_force_n() -> Vector3:
	return _last_drag_force_n


func get_last_buoyancy_force_n() -> Vector3:
	return _last_buoyancy_force_n


func export_machine_config() -> Dictionary:
	var thruster_rows: Array[Dictionary] = []
	for child: Node in _thrusters_root.get_children():
		var thruster_node: Node3D = child as Node3D
		if thruster_node == null:
			continue
		thruster_rows.append({
			"instance_id": child.name,
			"display_name": str(child.get("display_name")),
			"template_path": "",
			"position_m": thruster_node.position,
			"rotation_rad": thruster_node.rotation,
			"command_group": "main",
			"enabled": true,
			"mount_note": "",
			"max_thrust_n": float(child.get("max_thrust_n")),
			"local_force_axis": child.get("local_force_axis"),
		})
	return {
		"machine_id": "active_machine",
		"display_name": "Active ROV",
		"frame_model_path": frame_model_path,
		"mass_kg": mass_kg,
		"displaced_volume_m3": displaced_volume_m3,
		"body_size_m": Vector3(1.05, 0.36, 0.78),
		"center_of_mass_m": center_of_mass_m,
		"center_of_buoyancy_m": center_of_buoyancy_m,
		"drag_coefficients": drag_coefficients,
		"linear_drag_coefficients": linear_drag_coefficients,
		"angular_drag": angular_drag,
		"thrusters": thruster_rows,
	}


func _apply_body_parameters() -> void:
	if _body == null:
		return
	_body.mass = mass_kg
	_body.gravity_scale = 1.0
	_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_body.center_of_mass = center_of_mass_m


func _clear_thrusters() -> void:
	for child: Node in _thrusters_root.get_children():
		child.queue_free()


func _clear_frame_model() -> void:
	if _imported_frame_root == null:
		return
	for child: Node in _imported_frame_root.get_children():
		child.queue_free()


func _get_thruster_node(index: int) -> Node3D:
	if index < 0 or index >= _thrusters_root.get_child_count():
		return null
	return _thrusters_root.get_child(index) as Node3D


func _import_gltf_frame(path: String) -> bool:
	var gltf_document: GLTFDocument = GLTFDocument.new()
	var gltf_state: GLTFState = GLTFState.new()
	var error_code: Error = gltf_document.append_from_file(path, gltf_state)
	if error_code != OK:
		return false
	var imported_scene: Node = gltf_document.generate_scene(gltf_state)
	if imported_scene == null:
		return false
	_imported_frame_root.add_child(imported_scene)
	return true


func _create_thruster(index: int, config: Dictionary) -> void:
	var thruster: Node3D = ROVThrusterScene.instantiate()
	thruster.name = str(config.get("name", "Thruster_%d" % index))
	thruster.set("thruster_id", index)
	thruster.set("display_name", str(config.get("label", "T%d" % index)))
	thruster.set("max_thrust_n", float(config.get("max_thrust_n", 35.0)))
	thruster.set("local_force_axis", config.get("local_force_axis", Vector3(0.0, 0.0, -1.0)))
	var template: RefCounted = ThrusterTemplateScript.new()
	template.set("max_forward_thrust_n", float(config.get("max_thrust_n", 35.0)))
	template.set("force_axis_local", config.get("local_force_axis", Vector3(0.0, 0.0, -1.0)))
	thruster.call("apply_template", template)
	_thrusters_root.add_child(thruster)
	thruster.position = config.get("position_m", Vector3.ZERO)
	thruster.rotation = config.get("rotation_rad", Vector3.ZERO)
	thruster.call("set_command", float(config.get("command", 0.0)))


func _apply_hydrodynamics() -> void:
	var buoyancy_force: Vector3 = Vector3.UP * fluid_density_kg_m3 * gravity_mps2 * displaced_volume_m3
	var buoyancy_offset: Vector3 = _body.global_transform.basis * center_of_buoyancy_m
	_body.apply_force(buoyancy_force, buoyancy_offset)
	_last_buoyancy_force_n = buoyancy_force
	_add_force_sample("buoyancy", "Buoyancy", _body.global_position + buoyancy_offset, buoyancy_force, buoyancy_offset.cross(buoyancy_force), Color(0.2, 0.82, 0.38, 1.0), "buoyancy")

	var gravity_force: Vector3 = Vector3.DOWN * mass_kg * gravity_mps2
	var gravity_origin: Vector3 = _body.global_position + (_body.global_transform.basis * center_of_mass_m)
	_last_gravity_force_n = gravity_force
	_add_force_sample("gravity", "Gravity", gravity_origin, gravity_force, Vector3.ZERO, Color(1.0, 0.86, 0.18, 1.0), "gravity")

	var relative_velocity: Vector3 = _last_environment_state.get("relative_velocity_mps")
	var local_velocity: Vector3 = _body.global_transform.basis.inverse() * relative_velocity
	var local_drag: Vector3 = Vector3(
		-local_velocity.x * linear_drag_coefficients.x - _signed_square(local_velocity.x) * drag_coefficients.x,
		-local_velocity.y * linear_drag_coefficients.y - _signed_square(local_velocity.y) * drag_coefficients.y,
		-local_velocity.z * linear_drag_coefficients.z - _signed_square(local_velocity.z) * drag_coefficients.z
	)
	var world_drag: Vector3 = _body.global_transform.basis * local_drag
	_body.apply_central_force(world_drag)
	_last_drag_force_n = world_drag
	_add_force_sample("drag", "Drag", _body.global_position, world_drag, Vector3.ZERO, Color(0.15, 0.48, 1.0, 1.0), "drag")

	var angular_resistance: Vector3 = Vector3(
		-_signed_square(_body.angular_velocity.x) * angular_drag.x,
		-_signed_square(_body.angular_velocity.y) * angular_drag.y,
		-_signed_square(_body.angular_velocity.z) * angular_drag.z
	)
	_body.apply_torque(angular_resistance)
	_add_force_sample("torque", "Angular Drag", _body.global_position, Vector3.ZERO, angular_resistance, Color(0.72, 0.3, 1.0, 1.0), "angular_drag")


func _apply_control_system(_delta: float) -> void:
	var assist_force: Vector3 = Vector3.ZERO
	var assist_torque: Vector3 = Vector3.ZERO
	var state: RefCounted = get_current_state()
	var depth: float = float(state.get("depth_m"))
	var rotation: Quaternion = state.get("rotation_quat")
	var euler: Vector3 = rotation.get_euler()
	var yaw: float = euler.y
	var depth_error: float = target_depth_m - depth
	var heading_error: float = _wrap_angle(target_heading_rad - yaw)
	var speed_error: float = target_speed_mps - _body.linear_velocity.length()
	if control_mode == 1:
		assist_force.y = clampf(-depth_error * 120.0 - _body.linear_velocity.y * 70.0, -220.0, 220.0)
	elif control_mode == 2:
		assist_torque.y = clampf(heading_error * 80.0 - _body.angular_velocity.y * 35.0, -110.0, 110.0)
	elif control_mode == 3:
		assist_force.y = clampf(-depth_error * 70.0 - _body.linear_velocity.y * 45.0, -150.0, 150.0)
		assist_torque = Vector3(
			clampf(-euler.x * 60.0 - _body.angular_velocity.x * 28.0, -80.0, 80.0),
			clampf(heading_error * 45.0 - _body.angular_velocity.y * 22.0, -80.0, 80.0),
			clampf(-euler.z * 60.0 - _body.angular_velocity.z * 28.0, -80.0, 80.0)
		)
	if not assist_force.is_zero_approx():
		_body.apply_central_force(assist_force)
		_add_force_sample("control", "Control Assist", _body.global_position, assist_force, Vector3.ZERO, Color(0.0, 0.92, 0.86, 1.0), "control")
	if not assist_torque.is_zero_approx():
		_body.apply_torque(assist_torque)
		_add_force_sample("control_torque", "Control Torque", _body.global_position, Vector3.ZERO, assist_torque, Color(0.0, 0.68, 0.95, 1.0), "control")
	_refresh_control_state(assist_force, assist_torque, depth_error, heading_error, speed_error)


func _apply_thruster_forces() -> void:
	for child: Node in _thrusters_root.get_children():
		if not child.has_method("get_force_world"):
			continue
		var thruster_node: Node3D = child as Node3D
		var force: Vector3 = child.call("get_force_world")
		var offset: Vector3 = thruster_node.global_position - _body.global_position
		_body.apply_force(force, offset)
		_add_force_sample("thruster", str(child.get("display_name")), thruster_node.global_position, force, offset.cross(force), Color(1.0, 0.12, 0.08, 1.0), child.name)


func _add_force_sample(force_type: String, label: String, origin_m: Vector3, vector_n: Vector3, torque_nm: Vector3, color: Color, source_id: String) -> void:
	var sample: RefCounted = ForceSampleScript.new()
	sample.set("force_type", force_type)
	sample.set("label", label)
	sample.set("origin_m", origin_m)
	sample.set("vector_n", vector_n)
	sample.set("torque_nm", torque_nm)
	sample.set("color", color)
	sample.set("source_id", source_id)
	_current_frame_samples.append(sample)


func _build_force_snapshot() -> void:
	var snapshot: RefCounted = ForceSnapshotScript.new()
	snapshot.set("time_s", simulation_time_s)
	for sample: RefCounted in _current_frame_samples:
		snapshot.call("add_sample", sample)
	var net_sample: RefCounted = ForceSampleScript.new()
	net_sample.set("force_type", "net")
	net_sample.set("label", "Net Force")
	net_sample.set("origin_m", _body.global_position)
	net_sample.set("vector_n", snapshot.get("net_force_n"))
	net_sample.set("torque_nm", snapshot.get("net_torque_nm"))
	net_sample.set("color", Color(1.0, 1.0, 1.0, 1.0))
	net_sample.set("source_id", "net")
	var samples: Array[RefCounted] = snapshot.get("samples")
	samples.append(net_sample)
	snapshot.set("samples", samples)
	_last_force_snapshot = snapshot


func _refresh_environment_state() -> void:
	var current_velocity: Vector3 = _compute_current_velocity()
	var environment_state: RefCounted = EnvironmentStateScript.new()
	environment_state.set("time_s", simulation_time_s)
	environment_state.set("current_mode", current_mode)
	environment_state.set("current_velocity_mps", current_velocity)
	environment_state.set("relative_velocity_mps", _body.linear_velocity - current_velocity if _body != null else Vector3.ZERO)
	environment_state.set("linear_drag_coefficients", linear_drag_coefficients)
	environment_state.set("quadratic_drag_coefficients", drag_coefficients)
	environment_state.set("turbulence_strength", turbulence_strength)
	environment_state.set("water_density_kg_m3", fluid_density_kg_m3)
	_last_environment_state = environment_state


func _refresh_sensor_frame() -> void:
	var current_velocity: Vector3 = _last_environment_state.get("current_velocity_mps")
	var net_force: Vector3 = _last_force_snapshot.get("net_force_n")
	_last_sensor_frame = SensorSuiteScript.build_frame(simulation_time_s, _body, current_velocity, net_force, mass_kg)


func _refresh_control_state(assist_force: Vector3, assist_torque: Vector3, depth_error: float = 0.0, heading_error: float = 0.0, speed_error: float = 0.0) -> void:
	var control_state: RefCounted = ControlStateScript.new()
	control_state.set("time_s", simulation_time_s)
	control_state.set("mode", control_mode)
	control_state.set("target_depth_m", target_depth_m)
	control_state.set("target_heading_rad", target_heading_rad)
	control_state.set("target_speed_mps", target_speed_mps)
	control_state.set("depth_error_m", depth_error)
	control_state.set("heading_error_rad", heading_error)
	control_state.set("speed_error_mps", speed_error)
	control_state.set("assist_force_n", assist_force)
	control_state.set("assist_torque_nm", assist_torque)
	control_state.set("saturated_thruster_ratio", _calculate_saturated_thruster_ratio())
	control_state.set("mode_label_key", _control_mode_label_key(control_mode))
	control_state.set("task_status_key", _task_status_key(control_mode, depth_error, heading_error, speed_error))
	_last_control_state = control_state


func _compute_current_velocity() -> Vector3:
	var current_velocity: Vector3 = base_current_velocity_mps
	if current_mode >= 1 and _body != null:
		var depth: float = maxf(0.0, -_body.global_position.y)
		current_velocity += layered_current_gradient_mps_per_m * depth
	if current_mode >= 2:
		current_velocity += Vector3(
			sin(simulation_time_s * 0.7) * turbulence_strength,
			0.0,
			cos(simulation_time_s * 0.5) * turbulence_strength
		)
	return current_velocity


func _calculate_saturated_thruster_ratio() -> float:
	var total_count: int = _thrusters_root.get_child_count()
	if total_count <= 0:
		return 0.0
	var saturated_count: int = 0
	for child: Node in _thrusters_root.get_children():
		if absf(float(child.get("command"))) >= 0.98:
			saturated_count += 1
	return float(saturated_count) / float(total_count)


func _control_mode_label_key(mode: int) -> String:
	match mode:
		1:
			return "CONTROL_MODE_DEPTH_HOLD"
		2:
			return "CONTROL_MODE_HEADING_HOLD"
		3:
			return "CONTROL_MODE_STABILIZE"
		_:
			return "CONTROL_MODE_MANUAL"


func _task_status_key(mode: int, depth_error: float, heading_error: float, speed_error: float) -> String:
	if mode <= 0:
		return "TASK_STATUS_IDLE"
	if absf(depth_error) <= 0.12 and absf(heading_error) <= deg_to_rad(4.0) and absf(speed_error) <= 0.15:
		return "TASK_STATUS_REACHED"
	if absf(depth_error) > 1.0 or absf(heading_error) > deg_to_rad(30.0):
		return "TASK_STATUS_DEVIATED"
	return "TASK_STATUS_RUNNING"


func _signed_square(value: float) -> float:
	return signf(value) * value * value


func _wrap_angle(value: float) -> float:
	return atan2(sin(value), cos(value))


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
