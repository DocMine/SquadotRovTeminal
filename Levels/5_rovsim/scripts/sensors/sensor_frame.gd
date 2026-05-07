## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name SensorFrame
extends RefCounted

var time_s: float = 0.0
var imu_acceleration_mps2: Vector3 = Vector3.ZERO
var imu_angular_velocity_radps: Vector3 = Vector3.ZERO
var imu_orientation_quat: Quaternion = Quaternion.IDENTITY
var depth_m: float = 0.0
var compass_heading_rad: float = 0.0
var dvl_velocity_mps: Vector3 = Vector3.ZERO
var position_observation_m: Vector3 = Vector3.ZERO
var sensor_health: float = 1.0
var noise_level: float = 0.0
var delay_s: float = 0.0


func duplicate_frame() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.imu_acceleration_mps2 = imu_acceleration_mps2
	copied.imu_angular_velocity_radps = imu_angular_velocity_radps
	copied.imu_orientation_quat = imu_orientation_quat
	copied.depth_m = depth_m
	copied.compass_heading_rad = compass_heading_rad
	copied.dvl_velocity_mps = dvl_velocity_mps
	copied.position_observation_m = position_observation_m
	copied.sensor_health = sensor_health
	copied.noise_level = noise_level
	copied.delay_s = delay_s
	return copied


func to_dictionary() -> Dictionary:
	return {
		"time_s": time_s,
		"imu_acceleration_mps2": _vector_to_array(imu_acceleration_mps2),
		"imu_angular_velocity_radps": _vector_to_array(imu_angular_velocity_radps),
		"imu_orientation_quat": _quaternion_to_array(imu_orientation_quat),
		"depth_m": depth_m,
		"compass_heading_rad": compass_heading_rad,
		"dvl_velocity_mps": _vector_to_array(dvl_velocity_mps),
		"position_observation_m": _vector_to_array(position_observation_m),
		"sensor_health": sensor_health,
		"noise_level": noise_level,
		"delay_s": delay_s,
	}


func load_dictionary(data: Dictionary) -> void:
	time_s = float(data.get("time_s", time_s))
	imu_acceleration_mps2 = _array_to_vector(data.get("imu_acceleration_mps2", _vector_to_array(imu_acceleration_mps2)))
	imu_angular_velocity_radps = _array_to_vector(data.get("imu_angular_velocity_radps", _vector_to_array(imu_angular_velocity_radps)))
	imu_orientation_quat = _array_to_quaternion(data.get("imu_orientation_quat", _quaternion_to_array(imu_orientation_quat)))
	depth_m = float(data.get("depth_m", depth_m))
	compass_heading_rad = float(data.get("compass_heading_rad", compass_heading_rad))
	dvl_velocity_mps = _array_to_vector(data.get("dvl_velocity_mps", _vector_to_array(dvl_velocity_mps)))
	position_observation_m = _array_to_vector(data.get("position_observation_m", _vector_to_array(position_observation_m)))
	sensor_health = float(data.get("sensor_health", sensor_health))
	noise_level = float(data.get("noise_level", noise_level))
	delay_s = float(data.get("delay_s", delay_s))


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))


func _quaternion_to_array(value: Quaternion) -> Array[float]:
	return [value.x, value.y, value.z, value.w]


func _array_to_quaternion(value: Variant) -> Quaternion:
	if typeof(value) == TYPE_QUATERNION:
		return value
	var rows: Array = value
	if rows.size() < 4:
		return Quaternion.IDENTITY
	return Quaternion(float(rows[0]), float(rows[1]), float(rows[2]), float(rows[3]))
