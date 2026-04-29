extends Control

## 仪表盘面板（Dashboard Panel）
##
## 作用：
## - 监听 DataRecorder.frame_recorded
## - 把最新一帧数据以“文本形式”展示出来（深度、速度、姿态角、推进器推力等）
##
## 设计取舍：
## - Dashboard 只展示“最新值”，不需要窗口帧序列
## - 当数据为空（例如未开始录制/仿真未就绪）时，用 _set_empty() 统一显示占位符
## - 姿态使用四元数转欧拉角显示为 Roll/Pitch/Yaw（单位：度）

var _rec: Node

@onready var _depth: Label = $Margin/Root/Depth
@onready var _speed: Label = $Margin/Root/Velocity
@onready var _rpy: Label = $Margin/Root/RPY
@onready var _thrusters: RichTextLabel = $Margin/Root/Thrusters


func setup(data_recorder: Node) -> void:
	# 注入数据源并监听新帧事件
	_rec = data_recorder
	_rec.frame_recorded.connect(_on_frame)
	# 初始化为占位符，避免 UI 刚出现时显示旧值/空字符串
	_set_empty()


func _set_empty() -> void:
	# 统一的“无数据”显示
	_depth.text = "Depth: -"
	_speed.text = "Velocity: -"
	_rpy.text = "RPY: -"
	_thrusters.clear()


func _on_frame(f) -> void:
	# 每来一帧就刷新 UI（这里只用最新帧）
	if f == null or f.state == null:
		_set_empty()
		return
	_depth.text = "Depth: %.2f m" % f.state.depth_m
	_speed.text = "Velocity: %.2f m/s" % f.state.linear_velocity_mps.length()

	# 姿态：四元数 -> 欧拉角（弧度）-> 角度
	var e = Basis(f.state.rotation_quat).get_euler()
	var roll_deg = rad_to_deg(e.z)
	var pitch_deg = rad_to_deg(e.x)
	var yaw_deg = rad_to_deg(e.y)
	_rpy.text = "Roll: %.1f°  Pitch: %.1f°  Yaw: %.1f°" % [roll_deg, pitch_deg, yaw_deg]

	# 推进器列表：RichTextLabel 逐行追加文本
	_thrusters.clear()
	for t in f.thrusters:
		_thrusters.add_text("%s: %.1f N (cmd=%.2f)\n" % [t.name, t.thrust_n, t.command])
