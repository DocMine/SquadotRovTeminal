## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ThrusterTemplate
extends RefCounted

var template_id: String = "default_thruster"
var display_name: String = "ROV Thruster"
var manufacturer: String = "Generic"
var model_name: String = "T35"
var max_forward_thrust_n: float = 35.0
var max_reverse_thrust_n: float = 28.0
var response_time_s: float = 0.18
var dead_zone: float = 0.04
var efficiency: float = 0.78
var power_w: float = 180.0
var diameter_m: float = 0.16
var length_m: float = 0.24
var body_color: Color = Color(0.18, 0.34, 0.42, 1.0)
var axis_color: Color = Color(1.0, 0.18, 0.12, 1.0)
var propeller_color: Color = Color(0.08, 0.11, 0.14, 1.0)
var force_axis_local: Vector3 = Vector3(0.0, 0.0, -1.0)
var thrust_curve: Array[Vector2] = [
	Vector2(-1.0, -0.8),
	Vector2(0.0, 0.0),
	Vector2(1.0, 1.0),
]


func duplicate_template() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.template_id = template_id
	copied.display_name = display_name
	copied.manufacturer = manufacturer
	copied.model_name = model_name
	copied.max_forward_thrust_n = max_forward_thrust_n
	copied.max_reverse_thrust_n = max_reverse_thrust_n
	copied.response_time_s = response_time_s
	copied.dead_zone = dead_zone
	copied.efficiency = efficiency
	copied.power_w = power_w
	copied.diameter_m = diameter_m
	copied.length_m = length_m
	copied.body_color = body_color
	copied.axis_color = axis_color
	copied.propeller_color = propeller_color
	copied.force_axis_local = force_axis_local
	copied.thrust_curve = thrust_curve.duplicate()
	return copied


func evaluate_thrust(command_value: float) -> float:
	var clamped_command: float = clampf(command_value, -1.0, 1.0)
	if absf(clamped_command) < dead_zone:
		return 0.0
	var normalized_force: float = _evaluate_curve(clamped_command)
	if normalized_force >= 0.0:
		return normalized_force * max_forward_thrust_n
	return normalized_force * max_reverse_thrust_n


func to_dictionary() -> Dictionary:
	var curve_rows: Array[Array] = []
	for point: Vector2 in thrust_curve:
		curve_rows.append([point.x, point.y])
	return {
		"template_id": template_id,
		"display_name": display_name,
		"manufacturer": manufacturer,
		"model_name": model_name,
		"max_forward_thrust_n": max_forward_thrust_n,
		"max_reverse_thrust_n": max_reverse_thrust_n,
		"response_time_s": response_time_s,
		"dead_zone": dead_zone,
		"efficiency": efficiency,
		"power_w": power_w,
		"diameter_m": diameter_m,
		"length_m": length_m,
		"body_color": _color_to_array(body_color),
		"axis_color": _color_to_array(axis_color),
		"propeller_color": _color_to_array(propeller_color),
		"force_axis_local": _vector_to_array(force_axis_local),
		"thrust_curve": curve_rows,
	}


func load_dictionary(data: Dictionary) -> void:
	template_id = str(data.get("template_id", template_id))
	display_name = str(data.get("display_name", display_name))
	manufacturer = str(data.get("manufacturer", manufacturer))
	model_name = str(data.get("model_name", model_name))
	max_forward_thrust_n = float(data.get("max_forward_thrust_n", max_forward_thrust_n))
	max_reverse_thrust_n = float(data.get("max_reverse_thrust_n", max_reverse_thrust_n))
	response_time_s = float(data.get("response_time_s", response_time_s))
	dead_zone = float(data.get("dead_zone", dead_zone))
	efficiency = float(data.get("efficiency", efficiency))
	power_w = float(data.get("power_w", power_w))
	diameter_m = float(data.get("diameter_m", diameter_m))
	length_m = float(data.get("length_m", length_m))
	body_color = _array_to_color(data.get("body_color", _color_to_array(body_color)))
	axis_color = _array_to_color(data.get("axis_color", _color_to_array(axis_color)))
	propeller_color = _array_to_color(data.get("propeller_color", _color_to_array(propeller_color)))
	force_axis_local = _array_to_vector(data.get("force_axis_local", _vector_to_array(force_axis_local)))
	thrust_curve = []
	var curve_rows: Array = data.get("thrust_curve", [])
	for row_variant: Variant in curve_rows:
		var row: Array = row_variant
		if row.size() >= 2:
			thrust_curve.append(Vector2(float(row[0]), float(row[1])))
	if thrust_curve.is_empty():
		thrust_curve = [Vector2(-1.0, -0.8), Vector2(0.0, 0.0), Vector2(1.0, 1.0)]


func _evaluate_curve(command_value: float) -> float:
	if thrust_curve.is_empty():
		return command_value
	var sorted_curve: Array[Vector2] = thrust_curve.duplicate()
	sorted_curve.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x
	)
	if command_value <= sorted_curve[0].x:
		return sorted_curve[0].y
	for index: int in range(1, sorted_curve.size()):
		var previous: Vector2 = sorted_curve[index - 1]
		var current: Vector2 = sorted_curve[index]
		if command_value <= current.x:
			var weight: float = inverse_lerp(previous.x, current.x, command_value)
			return lerpf(previous.y, current.y, weight)
	return sorted_curve[sorted_curve.size() - 1].y


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _array_to_vector(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return value
	var rows: Array = value
	if rows.size() < 3:
		return Vector3.ZERO
	return Vector3(float(rows[0]), float(rows[1]), float(rows[2]))


func _color_to_array(value: Color) -> Array[float]:
	return [value.r, value.g, value.b, value.a]


func _array_to_color(value: Variant) -> Color:
	if typeof(value) == TYPE_COLOR:
		return value
	var rows: Array = value
	if rows.size() < 4:
		return Color.WHITE
	return Color(float(rows[0]), float(rows[1]), float(rows[2]), float(rows[3]))
