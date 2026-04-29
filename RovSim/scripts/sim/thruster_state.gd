extends Resource
class_name ThrusterState

## 推进器状态快照（ThrusterState）
##
## 这是一个可序列化的数据结构，用来记录某一时刻单个推进器的状态：
## - id：推进器标识（用于区分/匹配）
## - name：推进器名称（用于 UI 显示）
## - command：归一化指令 [-1, 1]
## - thrust_n：实际推力（牛顿），由 Thruster.get_thrust_n() 得到
##
## 用途：
## - DataRecorder 采样时生成 DataFrame.thrusters
## - Dashboard/Charts 展示推进器输出
## - RecordingIO 保存/读取回放数据
##
## 序列化约定：
## - to_dict(): ThrusterState -> Dictionary
## - from_dict(): Dictionary -> ThrusterState

const ThrusterStateScript := preload("res://RovSim/scripts/sim/thruster_state.gd")

@export var id: int = 0
@export var name: String = ""
@export var command: float = 0.0
@export var thrust_n: float = 0.0


func to_dict() -> Dictionary:
	# 转成可 JSON 化的字典结构
	return {
		"id": id,
		"name": name,
		"command": command,
		"thrust_n": thrust_n,
	}


static func from_dict(d: Dictionary):
	# 从字典恢复对象（输入通常来自 JSON.parse_string）
	var s = ThrusterStateScript.new()
	s.id = int(d.get("id", 0))
	s.name = str(d.get("name", ""))
	s.command = float(d.get("command", 0.0))
	s.thrust_n = float(d.get("thrust_n", 0.0))
	return s
