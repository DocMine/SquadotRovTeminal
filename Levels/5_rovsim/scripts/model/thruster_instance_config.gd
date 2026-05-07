## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ThrusterInstanceConfig
extends RefCounted

var instance_id: String = ""
var display_name: String = "T"
var template_path: String = ""
var position_m: Vector3 = Vector3.ZERO
var rotation_rad: Vector3 = Vector3.ZERO
var command_group: String = "main"
var enabled: bool = true
var mount_note: String = ""
var max_thrust_n: float = 35.0
var local_force_axis: Vector3 = Vector3(0.0, 0.0, -1.0)


func to_runtime_dictionary(command_value: float) -> Dictionary:
	return {
		"name": instance_id,
		"label": display_name,
		"template_path": template_path,
		"position_m": position_m,
		"rotation_rad": rotation_rad,
		"command_group": command_group,
		"enabled": enabled,
		"mount_note": mount_note,
		"max_thrust_n": max_thrust_n,
		"local_force_axis": local_force_axis,
		"command": command_value,
	}


func to_dictionary() -> Dictionary:
	return {
		"instance_id": instance_id,
		"display_name": display_name,
		"template_path": template_path,
		"position_m": _vector_to_array(position_m),
		"rotation_rad": _vector_to_array(rotation_rad),
		"command_group": command_group,
		"enabled": enabled,
		"mount_note": mount_note,
		"max_thrust_n": max_thrust_n,
		"local_force_axis": _vector_to_array(local_force_axis),
	}


func load_dictionary(data: Dictionary) -> void:
	instance_id = str(data.get("instance_id", data.get("name", instance_id)))
	display_name = str(data.get("display_name", data.get("label", display_name)))
	template_path = str(data.get("template_path", template_path))
	position_m = _array_to_vector(data.get("position_m", _vector_to_array(position_m)))
	rotation_rad = _array_to_vector(data.get("rotation_rad", _vector_to_array(rotation_rad)))
	command_group = str(data.get("command_group", command_group))
	enabled = bool(data.get("enabled", enabled))
	mount_note = str(data.get("mount_note", mount_note))
	max_thrust_n = float(data.get("max_thrust_n", max_thrust_n))
	local_force_axis = _array_to_vector(data.get("local_force_axis", _vector_to_array(local_force_axis)))


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
