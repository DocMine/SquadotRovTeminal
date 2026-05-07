## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name EnvironmentState
extends RefCounted

var time_s: float = 0.0
var current_mode: int = 0
var current_velocity_mps: Vector3 = Vector3.ZERO
var relative_velocity_mps: Vector3 = Vector3.ZERO
var linear_drag_coefficients: Vector3 = Vector3(8.0, 10.0, 8.0)
var quadratic_drag_coefficients: Vector3 = Vector3(42.0, 58.0, 46.0)
var turbulence_strength: float = 0.0
var water_density_kg_m3: float = 1000.0


func duplicate_state() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.current_mode = current_mode
	copied.current_velocity_mps = current_velocity_mps
	copied.relative_velocity_mps = relative_velocity_mps
	copied.linear_drag_coefficients = linear_drag_coefficients
	copied.quadratic_drag_coefficients = quadratic_drag_coefficients
	copied.turbulence_strength = turbulence_strength
	copied.water_density_kg_m3 = water_density_kg_m3
	return copied


func to_dictionary() -> Dictionary:
	return {
		"time_s": time_s,
		"current_mode": current_mode,
		"current_velocity_mps": _vector_to_array(current_velocity_mps),
		"relative_velocity_mps": _vector_to_array(relative_velocity_mps),
		"linear_drag_coefficients": _vector_to_array(linear_drag_coefficients),
		"quadratic_drag_coefficients": _vector_to_array(quadratic_drag_coefficients),
		"turbulence_strength": turbulence_strength,
		"water_density_kg_m3": water_density_kg_m3,
	}


func load_dictionary(data: Dictionary) -> void:
	time_s = float(data.get("time_s", time_s))
	current_mode = int(data.get("current_mode", current_mode))
	current_velocity_mps = _array_to_vector(data.get("current_velocity_mps", _vector_to_array(current_velocity_mps)))
	relative_velocity_mps = _array_to_vector(data.get("relative_velocity_mps", _vector_to_array(relative_velocity_mps)))
	linear_drag_coefficients = _array_to_vector(data.get("linear_drag_coefficients", _vector_to_array(linear_drag_coefficients)))
	quadratic_drag_coefficients = _array_to_vector(data.get("quadratic_drag_coefficients", _vector_to_array(quadratic_drag_coefficients)))
	turbulence_strength = float(data.get("turbulence_strength", turbulence_strength))
	water_density_kg_m3 = float(data.get("water_density_kg_m3", water_density_kg_m3))


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
