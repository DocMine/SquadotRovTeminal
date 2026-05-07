## 本脚本负责对应场景或模块的局部逻辑与节点协作。
extends RefCounted


static func export_frames(path: String, frames: Array[RefCounted]) -> bool:
	var normalized_path: String = path
	if normalized_path.begins_with("user://") or normalized_path.begins_with("res://"):
		normalized_path = ProjectSettings.globalize_path(normalized_path)
	var directory_path: String = normalized_path.get_base_dir()
	if not directory_path.is_empty():
		DirAccess.make_dir_recursive_absolute(directory_path)
	var file: FileAccess = FileAccess.open(normalized_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open CSV for write: %s" % normalized_path)
		return false
	file.store_line("time_s,depth_m,pos_x,pos_y,pos_z,speed_mps,roll_deg,pitch_deg,yaw_deg,net_force_n,net_torque_nm,current_x_mps,current_z_mps,sensor_depth_m,compass_heading_deg,control_mode,task_status,depth_error_m,heading_error_deg,assist_force_n,assist_torque_nm,thruster_saturation")
	for frame: RefCounted in frames:
		var state: RefCounted = frame.get("state")
		var position: Vector3 = state.get("position_m")
		var velocity: Vector3 = state.get("linear_velocity_mps")
		var rotation: Quaternion = state.get("rotation_quat")
		var euler: Vector3 = rotation.get_euler()
		var force_snapshot: RefCounted = frame.get("force_snapshot")
		var net_force: Vector3 = force_snapshot.get("net_force_n")
		var net_torque: Vector3 = force_snapshot.get("net_torque_nm")
		var environment_state: RefCounted = frame.get("environment_state")
		var current_velocity: Vector3 = environment_state.get("current_velocity_mps")
		var sensor_frame: RefCounted = frame.get("sensor_frame")
		var control_state: RefCounted = frame.get("control_state")
		file.store_line("%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%s,%.4f,%.4f,%.4f,%.4f,%.4f" % [
			float(frame.get("time_s")),
			float(state.get("depth_m")),
			position.x,
			position.y,
			position.z,
			velocity.length(),
			rad_to_deg(euler.z),
			rad_to_deg(euler.x),
			rad_to_deg(euler.y),
			net_force.length(),
			net_torque.length(),
			current_velocity.x,
			current_velocity.z,
			float(sensor_frame.get("depth_m")),
			rad_to_deg(float(sensor_frame.get("compass_heading_rad"))),
			int(control_state.get("mode")),
			str(control_state.get("task_status_key")),
			float(control_state.get("depth_error_m")),
			rad_to_deg(float(control_state.get("heading_error_rad"))),
			Vector3(control_state.get("assist_force_n")).length(),
			Vector3(control_state.get("assist_torque_nm")).length(),
			float(control_state.get("saturated_thruster_ratio")),
		])
	return true
