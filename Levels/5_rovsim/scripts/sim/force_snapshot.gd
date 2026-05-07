## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ForceSnapshot
extends RefCounted

const ForceSampleScript = preload("res://Levels/5_rovsim/scripts/sim/force_sample.gd")

var time_s: float = 0.0
var samples: Array[RefCounted] = []
var net_force_n: Vector3 = Vector3.ZERO
var net_torque_nm: Vector3 = Vector3.ZERO


func add_sample(sample: RefCounted) -> void:
	samples.append(sample)
	net_force_n += sample.get("vector_n")
	net_torque_nm += sample.get("torque_nm")


func duplicate_snapshot() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.net_force_n = net_force_n
	copied.net_torque_nm = net_torque_nm
	for sample: RefCounted in samples:
		copied.samples.append(sample.call("duplicate_sample"))
	return copied


func to_dictionary() -> Dictionary:
	var rows: Array[Dictionary] = []
	for sample: RefCounted in samples:
		rows.append(sample.call("to_dictionary"))
	return {
		"time_s": time_s,
		"samples": rows,
		"net_force_n": _vector_to_array(net_force_n),
		"net_torque_nm": _vector_to_array(net_torque_nm),
	}


func load_dictionary(data: Dictionary) -> void:
	time_s = float(data.get("time_s", time_s))
	net_force_n = _array_to_vector(data.get("net_force_n", _vector_to_array(net_force_n)))
	net_torque_nm = _array_to_vector(data.get("net_torque_nm", _vector_to_array(net_torque_nm)))
	samples.clear()
	var rows: Array = data.get("samples", [])
	for row_variant: Variant in rows:
		var sample: RefCounted = ForceSampleScript.new()
		sample.call("load_dictionary", row_variant)
		samples.append(sample)


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))
