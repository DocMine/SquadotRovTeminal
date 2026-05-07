## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name MachineConfig
extends RefCounted

const ThrusterInstanceConfigScript = preload("res://Levels/5_rovsim/scripts/model/thruster_instance_config.gd")

var machine_id: String = "machine_default"
var display_name: String = "ROV Machine"
var frame_model_path: String = ""
var mass_kg: float = 50.0
var displaced_volume_m3: float = 0.051
var body_size_m: Vector3 = Vector3(1.05, 0.36, 0.78)
var center_of_mass_m: Vector3 = Vector3(0.0, -0.04, 0.0)
var center_of_buoyancy_m: Vector3 = Vector3(0.0, 0.18, 0.0)
var drag_coefficients: Vector3 = Vector3(42.0, 58.0, 46.0)
var linear_drag_coefficients: Vector3 = Vector3(8.0, 10.0, 8.0)
var angular_drag: Vector3 = Vector3(3.2, 3.8, 3.2)
var thruster_instances: Array[RefCounted] = []


func to_runtime_dictionary(command_value: float) -> Dictionary:
	var thruster_rows: Array[Dictionary] = []
	for instance: RefCounted in thruster_instances:
		if bool(instance.get("enabled")):
			thruster_rows.append(instance.call("to_runtime_dictionary", command_value))
	return {
		"machine_id": machine_id,
		"display_name": display_name,
		"frame_model_path": frame_model_path,
		"mass_kg": mass_kg,
		"displaced_volume_m3": displaced_volume_m3,
		"body_size_m": body_size_m,
		"center_of_mass_m": center_of_mass_m,
		"center_of_buoyancy_m": center_of_buoyancy_m,
		"drag_coefficients": drag_coefficients,
		"linear_drag_coefficients": linear_drag_coefficients,
		"angular_drag": angular_drag,
		"thrusters": thruster_rows,
	}


func to_dictionary() -> Dictionary:
	var thruster_rows: Array[Dictionary] = []
	for instance: RefCounted in thruster_instances:
		thruster_rows.append(instance.call("to_dictionary"))
	return {
		"machine_id": machine_id,
		"display_name": display_name,
		"frame_model_path": frame_model_path,
		"mass_kg": mass_kg,
		"displaced_volume_m3": displaced_volume_m3,
		"body_size_m": _vector_to_array(body_size_m),
		"center_of_mass_m": _vector_to_array(center_of_mass_m),
		"center_of_buoyancy_m": _vector_to_array(center_of_buoyancy_m),
		"drag_coefficients": _vector_to_array(drag_coefficients),
		"linear_drag_coefficients": _vector_to_array(linear_drag_coefficients),
		"angular_drag": _vector_to_array(angular_drag),
		"thrusters": thruster_rows,
	}


func load_dictionary(data: Dictionary) -> void:
	machine_id = str(data.get("machine_id", machine_id))
	display_name = str(data.get("display_name", display_name))
	frame_model_path = str(data.get("frame_model_path", frame_model_path))
	mass_kg = float(data.get("mass_kg", mass_kg))
	displaced_volume_m3 = float(data.get("displaced_volume_m3", displaced_volume_m3))
	body_size_m = _array_to_vector(data.get("body_size_m", _vector_to_array(body_size_m)))
	center_of_mass_m = _array_to_vector(data.get("center_of_mass_m", _vector_to_array(center_of_mass_m)))
	center_of_buoyancy_m = _array_to_vector(data.get("center_of_buoyancy_m", _vector_to_array(center_of_buoyancy_m)))
	drag_coefficients = _array_to_vector(data.get("drag_coefficients", _vector_to_array(drag_coefficients)))
	linear_drag_coefficients = _array_to_vector(data.get("linear_drag_coefficients", _vector_to_array(linear_drag_coefficients)))
	angular_drag = _array_to_vector(data.get("angular_drag", _vector_to_array(angular_drag)))
	thruster_instances.clear()
	var thruster_rows: Array = data.get("thrusters", [])
	var index: int = 1
	for row_variant: Variant in thruster_rows:
		var row: Dictionary = row_variant
		var instance: RefCounted = ThrusterInstanceConfigScript.new()
		instance.call("load_dictionary", row)
		if str(instance.get("instance_id")).is_empty():
			instance.set("instance_id", "Thruster_%d" % index)
		thruster_instances.append(instance)
		index += 1


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
