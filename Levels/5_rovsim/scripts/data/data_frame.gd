## 本脚本负责对应场景或模块的局部逻辑与节点协作。
class_name DataFrame
extends RefCounted

const ROVStateScript = preload("res://Levels/5_rovsim/scripts/sim/rov_state.gd")
const ForceSnapshotScript = preload("res://Levels/5_rovsim/scripts/sim/force_snapshot.gd")
const EnvironmentStateScript = preload("res://Levels/5_rovsim/scripts/sim/environment_state.gd")
const SensorFrameScript = preload("res://Levels/5_rovsim/scripts/sensors/sensor_frame.gd")
const ControlStateScript = preload("res://Levels/5_rovsim/scripts/control/control_state.gd")

var time_s: float = 0.0
var state: RefCounted = ROVStateScript.new()
var thrusters: Array[RefCounted] = []
var force_snapshot: RefCounted = ForceSnapshotScript.new()
var environment_state: RefCounted = EnvironmentStateScript.new()
var sensor_frame: RefCounted = SensorFrameScript.new()
var control_state: RefCounted = ControlStateScript.new()


func duplicate_frame() -> RefCounted:
	var script: Script = get_script()
	var copied: RefCounted = script.new()
	copied.time_s = time_s
	copied.state = state.duplicate_state()
	var copied_thrusters: Array[RefCounted] = []
	for thruster: RefCounted in thrusters:
		copied_thrusters.append(thruster.duplicate_state())
	copied.thrusters = copied_thrusters
	copied.force_snapshot = force_snapshot.call("duplicate_snapshot")
	copied.environment_state = environment_state.call("duplicate_state")
	copied.sensor_frame = sensor_frame.call("duplicate_frame")
	copied.control_state = control_state.call("duplicate_state")
	return copied


func to_dictionary() -> Dictionary:
	var thruster_rows: Array[Dictionary] = []
	for thruster: RefCounted in thrusters:
		thruster_rows.append(thruster.to_dictionary())
	return {
		"time_s": time_s,
		"state": state.to_dictionary(),
		"thrusters": thruster_rows,
		"force_snapshot": force_snapshot.call("to_dictionary"),
		"environment_state": environment_state.call("to_dictionary"),
		"sensor_frame": sensor_frame.call("to_dictionary"),
		"control_state": control_state.call("to_dictionary"),
	}
