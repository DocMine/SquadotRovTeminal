extends Resource
class_name ROVState

## ROV 状态快照（ROVState）
##
## 这是一个可序列化的数据结构，用来记录某一时刻 ROV 的状态：
## - position_m：世界坐标位置（米）
## - linear_velocity_mps：世界坐标线速度（米/秒）
## - rotation_quat：世界坐标旋转（四元数）
## - angular_velocity_radps：世界坐标角速度（弧度/秒）
## - depth_m：深度（米，约定向下为正）
##
## 用途：
## - DataRecorder 采样时生成 DataFrame.state
## - Dashboard/Charts 展示时从中读取数据
## - RecordingIO 保存/读取回放数据
##
## 序列化约定：
## - to_dict(): ROVState -> Dictionary（基础类型 + 数组）
## - from_dict(): Dictionary -> ROVState

const ROVStateScript := preload("res://RovSim/scripts/sim/rov_state.gd")

@export var time_s: float = 0.0
@export var position_m: Vector3 = Vector3.ZERO
@export var linear_velocity_mps: Vector3 = Vector3.ZERO
@export var rotation_quat: Quaternion = Quaternion.IDENTITY
@export var angular_velocity_radps: Vector3 = Vector3.ZERO
@export var depth_m: float = 0.0


func to_dict() -> Dictionary:
	# 转成可 JSON 化的字典结构
	return {
		"time_s": time_s,
		"position_m": [position_m.x, position_m.y, position_m.z],
		"linear_velocity_mps": [linear_velocity_mps.x, linear_velocity_mps.y, linear_velocity_mps.z],
		"rotation_quat": [rotation_quat.x, rotation_quat.y, rotation_quat.z, rotation_quat.w],
		"angular_velocity_radps": [angular_velocity_radps.x, angular_velocity_radps.y, angular_velocity_radps.z],
		"depth_m": depth_m,
	}


static func from_dict(d: Dictionary):
	# 从字典恢复对象（输入通常来自 JSON.parse_string）
	var s = ROVStateScript.new()
	s.time_s = float(d.get("time_s", 0.0))
	var p = d.get("position_m", [0.0, 0.0, 0.0])
	s.position_m = Vector3(float(p[0]), float(p[1]), float(p[2]))
	var lv = d.get("linear_velocity_mps", [0.0, 0.0, 0.0])
	s.linear_velocity_mps = Vector3(float(lv[0]), float(lv[1]), float(lv[2]))
	var rq = d.get("rotation_quat", [0.0, 0.0, 0.0, 1.0])
	s.rotation_quat = Quaternion(float(rq[0]), float(rq[1]), float(rq[2]), float(rq[3]))
	var av = d.get("angular_velocity_radps", [0.0, 0.0, 0.0])
	s.angular_velocity_radps = Vector3(float(av[0]), float(av[1]), float(av[2]))
	s.depth_m = float(d.get("depth_m", 0.0))
	return s
