## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ROVState
extends RefCounted

var time_s: float = 0.0
var position_m: Vector3 = Vector3.ZERO
var linear_velocity_mps: Vector3 = Vector3.ZERO
var rotation_quat: Quaternion = Quaternion.IDENTITY
var angular_velocity_radps: Vector3 = Vector3.ZERO
var depth_m: float = 0.0


func duplicate_state() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.position_m = position_m
	copied.linear_velocity_mps = linear_velocity_mps
	copied.rotation_quat = rotation_quat
	copied.angular_velocity_radps = angular_velocity_radps
	copied.depth_m = depth_m
	return copied


func to_dictionary() -> Dictionary:
	return {
		"time_s": time_s,
		"position_m": _vector_to_array(position_m),
		"linear_velocity_mps": _vector_to_array(linear_velocity_mps),
		"rotation_quat": [rotation_quat.x, rotation_quat.y, rotation_quat.z, rotation_quat.w],
		"angular_velocity_radps": _vector_to_array(angular_velocity_radps),
		"depth_m": depth_m,
	}


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
