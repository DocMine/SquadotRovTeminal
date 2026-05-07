## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name ThrusterState
extends RefCounted

var id: int = 0
var display_name: String = ""
var command: float = 0.0
var thrust_n: float = 0.0
var max_thrust_n: float = 0.0
var position_m: Vector3 = Vector3.ZERO
var force_world_n: Vector3 = Vector3.ZERO


func duplicate_state() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.id = id
	copied.display_name = display_name
	copied.command = command
	copied.thrust_n = thrust_n
	copied.max_thrust_n = max_thrust_n
	copied.position_m = position_m
	copied.force_world_n = force_world_n
	return copied


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"command": command,
		"thrust_n": thrust_n,
		"max_thrust_n": max_thrust_n,
		"position_m": _vector_to_array(position_m),
		"force_world_n": _vector_to_array(force_world_n),
	}


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
