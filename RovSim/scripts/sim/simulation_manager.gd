extends Node

## 仿真管理器（SimulationManager）
##
## 这是仿真侧的“数据出口”和“时钟”：
## - 维护 simulation_time_s（随物理帧累加）
## - 持有当前的 rov（ROVController / RigidBody3D）
## - 提供 get_current_state / get_thruster_states 给 DataRecorder、UI 等模块读取
##
## 设计原则：
## - 这里不直接做控制算法/物理力计算（那些在 ROVController/Thruster 内部）
## - SimulationManager 只负责把“场景中的运行状态”整理成可序列化的数据结构（ROVState/ThrusterState）

const ROVStateScript := preload("res://RovSim/scripts/sim/rov_state.gd")
const ThrusterStateScript := preload("res://RovSim/scripts/sim/thruster_state.gd")

## 仿真时间（秒）。每个 _physics_process(delta) 都会 += delta。
var simulation_time_s: float = 0.0
## 当前参与仿真的 ROV 实例（通常由 PresetManager.set_rov 设置）。
var rov


func _physics_process(delta: float) -> void:
	# 仿真时钟：用物理步进时间累加
	simulation_time_s += delta


func set_rov(new_rov) -> void:
	# 切换当前 ROV（例如加载新预设或重建 ROV）
	rov = new_rov


func get_current_state():
	# 把当前 ROV 的运动学/姿态等信息打包成 ROVState
	var s := ROVStateScript.new()
	s.time_s = simulation_time_s
	if rov == null:
		return s
	s.position_m = rov.global_transform.origin
	s.linear_velocity_mps = rov.linear_velocity
	s.rotation_quat = rov.global_transform.basis.get_rotation_quaternion()
	s.angular_velocity_radps = rov.angular_velocity
	# 约定：水面为 y=0，向下为正深度，因此 depth = -y
	s.depth_m = -rov.global_transform.origin.y
	return s


func get_thruster_states() -> Array:
	# 收集推进器状态：每个推进器生成一个 ThrusterState
	var out: Array = []
	if rov == null:
		return out
	var thrusters: Array = rov.get_thrusters()
	out.resize(thrusters.size())
	for i in thrusters.size():
		var t = thrusters[i]
		var st := ThrusterStateScript.new()
		st.id = t.id
		st.name = t.name
		st.command = t.command
		st.thrust_n = t.get_thrust_n()
		out[i] = st
	return out
