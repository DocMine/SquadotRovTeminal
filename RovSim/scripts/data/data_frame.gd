extends Resource
class_name DataFrame

## 录制帧（DataFrame）
##
## DataRecorder 每次采样会生成一个 DataFrame，用来表示某个时间点的“快照”：
## - time_s：该帧对应的仿真时间（秒）
## - state：ROVState（位置、速度、姿态等连续状态）
## - thrusters：ThrusterState 数组（每个推进器当下输出/指令等）
##
## 为什么用 Resource 而不是 Node？
## - DataFrame 只是数据容器，不需要进场景树、也不需要生命周期回调
## - Resource 更适合序列化/反序列化（保存成 json、从 json 恢复）
##
## 序列化约定：
## - to_dict(): DataFrame -> Dictionary（适合 JSON.stringify）
## - from_dict(): Dictionary -> DataFrame（适合 JSON.parse_string 的结果）

const DataFrameScript := preload("res://RovSim/scripts/data/data_frame.gd")
const ROVStateScript := preload("res://RovSim/scripts/sim/rov_state.gd")
const ThrusterStateScript := preload("res://RovSim/scripts/sim/thruster_state.gd")

## 仿真时间戳（秒）
@export var time_s: float = 0.0
## ROV 的连续状态（通常是 ROVState）
@export var state: Resource
## 推进器状态数组（元素通常是 ThrusterState）
@export var thrusters: Array = []


func to_dict() -> Dictionary:
	# 转成可 JSON 化的字典结构（只包含基础类型/数组/字典）
	var thr = []
	thr.resize(thrusters.size())
	for i in thrusters.size():
		thr[i] = thrusters[i].to_dict()
	return {
		"time_s": time_s,
		"state": state.to_dict() if state != null else {},
		"thrusters": thr,
	}


static func from_dict(d: Dictionary):
	# 从字典恢复一帧。输入通常来自 JSON.parse_string。
	var f = DataFrameScript.new()
	f.time_s = float(d.get("time_s", 0.0))
	f.state = ROVStateScript.from_dict(d.get("state", {}))
	f.thrusters = []
	for t in d.get("thrusters", []):
		f.thrusters.append(ThrusterStateScript.from_dict(t))
	return f
