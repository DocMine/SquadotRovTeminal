## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ControlState
extends RefCounted

var time_s: float = 0.0
var mode: int = 0
var target_depth_m: float = 1.2
var target_heading_rad: float = 0.0
var target_speed_mps: float = 0.0
var depth_error_m: float = 0.0
var heading_error_rad: float = 0.0
var speed_error_mps: float = 0.0
var assist_force_n: Vector3 = Vector3.ZERO
var assist_torque_nm: Vector3 = Vector3.ZERO
var saturated_thruster_ratio: float = 0.0
var mode_label_key: String = "CONTROL_MODE_MANUAL"
var task_status_key: String = "TASK_STATUS_IDLE"


func duplicate_state() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.mode = mode
	copied.target_depth_m = target_depth_m
	copied.target_heading_rad = target_heading_rad
	copied.target_speed_mps = target_speed_mps
	copied.depth_error_m = depth_error_m
	copied.heading_error_rad = heading_error_rad
	copied.speed_error_mps = speed_error_mps
	copied.assist_force_n = assist_force_n
	copied.assist_torque_nm = assist_torque_nm
	copied.saturated_thruster_ratio = saturated_thruster_ratio
	copied.mode_label_key = mode_label_key
	copied.task_status_key = task_status_key
	return copied


func to_dictionary() -> Dictionary:
	return {
		"time_s": time_s,
		"mode": mode,
		"target_depth_m": target_depth_m,
		"target_heading_rad": target_heading_rad,
		"target_speed_mps": target_speed_mps,
		"depth_error_m": depth_error_m,
		"heading_error_rad": heading_error_rad,
		"speed_error_mps": speed_error_mps,
		"assist_force_n": _vector_to_array(assist_force_n),
		"assist_torque_nm": _vector_to_array(assist_torque_nm),
		"saturated_thruster_ratio": saturated_thruster_ratio,
		"mode_label_key": mode_label_key,
		"task_status_key": task_status_key,
	}


func load_dictionary(data: Dictionary) -> void:
	time_s = float(data.get("time_s", time_s))
	mode = int(data.get("mode", mode))
	target_depth_m = float(data.get("target_depth_m", target_depth_m))
	target_heading_rad = float(data.get("target_heading_rad", target_heading_rad))
	target_speed_mps = float(data.get("target_speed_mps", target_speed_mps))
	depth_error_m = float(data.get("depth_error_m", depth_error_m))
	heading_error_rad = float(data.get("heading_error_rad", heading_error_rad))
	speed_error_mps = float(data.get("speed_error_mps", speed_error_mps))
	assist_force_n = _array_to_vector(data.get("assist_force_n", _vector_to_array(assist_force_n)))
	assist_torque_nm = _array_to_vector(data.get("assist_torque_nm", _vector_to_array(assist_torque_nm)))
	saturated_thruster_ratio = float(data.get("saturated_thruster_ratio", saturated_thruster_ratio))
	mode_label_key = str(data.get("mode_label_key", mode_label_key))
	task_status_key = str(data.get("task_status_key", task_status_key))


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
