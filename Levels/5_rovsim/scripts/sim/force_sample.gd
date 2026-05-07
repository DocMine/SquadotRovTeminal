## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ForceSample
extends RefCounted

var force_type: String = ""
var label: String = ""
var origin_m: Vector3 = Vector3.ZERO
var vector_n: Vector3 = Vector3.ZERO
var torque_nm: Vector3 = Vector3.ZERO
var color: Color = Color.WHITE
var source_id: String = ""


func duplicate_sample() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.force_type = force_type
	copied.label = label
	copied.origin_m = origin_m
	copied.vector_n = vector_n
	copied.torque_nm = torque_nm
	copied.color = color
	copied.source_id = source_id
	return copied


func to_dictionary() -> Dictionary:
	return {
		"force_type": force_type,
		"label": label,
		"origin_m": _vector_to_array(origin_m),
		"vector_n": _vector_to_array(vector_n),
		"torque_nm": _vector_to_array(torque_nm),
		"color": [color.r, color.g, color.b, color.a],
		"source_id": source_id,
	}


func load_dictionary(data: Dictionary) -> void:
	force_type = str(data.get("force_type", force_type))
	label = str(data.get("label", label))
	origin_m = _array_to_vector(data.get("origin_m", _vector_to_array(origin_m)))
	vector_n = _array_to_vector(data.get("vector_n", _vector_to_array(vector_n)))
	torque_nm = _array_to_vector(data.get("torque_nm", _vector_to_array(torque_nm)))
	color = _array_to_color(data.get("color", [color.r, color.g, color.b, color.a]))
	source_id = str(data.get("source_id", source_id))


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))


func _array_to_color(value: Variant) -> Color:
	if typeof(value) == TYPE_COLOR:
		return value
	var rows: Array = value
	if rows.size() < 4:
		return Color.WHITE
	return Color(float(rows[0]), float(rows[1]), float(rows[2]), float(rows[3]))
